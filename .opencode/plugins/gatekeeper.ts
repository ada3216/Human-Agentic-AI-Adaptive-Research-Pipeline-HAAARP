// .opencode/plugins/gatekeeper.ts
// Gate 1 - tool.execute.after: lint advisory after source file writes
// Gate 2 - tool.execute.before: block git commit if check.sh fails
// Stateless. No per-file permissions. No hash-gate logic.

import { execSync } from "child_process";
import { existsSync } from "fs";

function run(cmd: string): { ok: boolean; output: string } {
  try {
    const out = execSync(cmd, {
      encoding: "utf8",
      stdio: ["pipe", "pipe", "pipe"],
    });
    return { ok: true, output: out.trim() };
  } catch (err: any) {
    return {
      ok: false,
      output: ((err.stdout ?? "") + (err.stderr ?? "")).trim(),
    };
  }
}

function isSourceFile(path: string): boolean {
  return /\.(ts|js|tsx|jsx|mjs|cjs|py|sh|bash)$/.test(path);
}

function extractPath(input: Record<string, unknown>): string | null {
  for (const key of ["path", "file_path", "filePath", "target_file"]) {
    if (typeof input[key] === "string") return input[key] as string;
  }
  return null;
}

type ToolBeforeInput = { tool: string; sessionID: string; callID: string };
type ToolBeforeOutput = { args: Record<string, unknown> };
type ToolAfterInput = { tool: string; sessionID: string; callID: string; args: Record<string, unknown> };
type ToolAfterOutput = { title: string; output: string; metadata: unknown };

// Plugin factory - required export shape for OpenCode plugin loader
export default async function (_ctx: unknown): Promise<{
  "tool.execute.before"(input: ToolBeforeInput, output: ToolBeforeOutput): Promise<void>;
  "tool.execute.after"(input: ToolAfterInput, output: ToolAfterOutput): Promise<void>;
}> {
  return {
    // Gate 2 - fires before tool runs: block git commit if check.sh fails
    async "tool.execute.before"(input: ToolBeforeInput, output: ToolBeforeOutput): Promise<void> {
      if (input.tool !== "bash") return;

      const cmd = (typeof output.args.command === "string" ? output.args.command : "").trim();
      if (!/^git\s+commit/.test(cmd)) return;
      if (!existsSync("scripts/check.sh")) return;

      const result = run("bash scripts/check.sh");
      if (!result.ok) {
        throw new Error(`GATE-2 BLOCK: check.sh failed. Fix before committing.\n\n${result.output}`);
      }
    },

    // Gate 1 - fires after tool runs: lint advisory after source file writes
    async "tool.execute.after"(input: ToolAfterInput, _output: ToolAfterOutput): Promise<void> {
      const writingTools = ["write", "edit", "apply_patch"];
      if (!writingTools.includes(input.tool)) return;

      const filePath = extractPath(input.args);
      // If path was extracted and it's not a source file, skip (e.g. markdown, images).
      // If path could NOT be extracted (patch-based writes like apply_patch may not
      // expose a single path key), fall through and run lint anyway - false silence
      // is worse than a redundant lint run.
      if (filePath && !isSourceFile(filePath)) return;
      if (!existsSync("scripts/lint-check.sh")) return;

      const result = run("bash scripts/lint-check.sh");
      if (!result.ok) {
        const label = filePath ?? "(path not extracted - patch-based write)";
        console.log(`\nGATE-1 ADVISORY: lint failed after writing ${label}`);
        console.log(result.output);
        console.log("Resolve lint violations before committing.");
      }
    },
  };
}
