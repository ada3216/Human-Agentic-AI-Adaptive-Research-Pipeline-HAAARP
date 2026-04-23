// .opencode/plugins/gatekeeper.ts
// Gate 1 - tool.execute.after: lint advisory after source file writes
// Gate 2 - tool.execute.before: block git commit if check.sh fails
// Stateless. No per-file permissions. No hash-gate logic.

import { execSync } from "child_process";
import { existsSync, readFileSync, readdirSync, appendFileSync } from "fs";
import { join, basename } from "path";

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

/**
 * Look up .rules.md files in tier-1/ that match failing rule names.
 * Returns formatted guidance string. Best-effort — never errors.
 */
function lookupRuleGuidance(lintOutput: string): string {
  const rulesDir = ".ai-layer/lint-rules/tier-1";
  if (!existsSync(rulesDir)) return "";

  let ruleFiles: string[];
  try {
    ruleFiles = readdirSync(rulesDir).filter((f) => f.endsWith(".rules.md"));
  } catch {
    return "";
  }

  if (ruleFiles.length === 0) return "";

  const blocks: string[] = [];
  for (const rf of ruleFiles) {
    const ruleName = rf.replace(/\.rules\.md$/, "");
    // Check if this rule name or its descriptor appears in lint output
    if (!lintOutput.includes(ruleName) && !lintOutput.toLowerCase().includes(ruleName.toLowerCase())) continue;
    try {
      const content = readFileSync(join(rulesDir, rf), "utf8");
      const appliesTo = content.match(/\*\*Applies to:\*\*\s*(.*)/)?.[1] ?? "";
      const example = content.match(/\*\*Example:\*\*\s*([\s\S]*?)(?=\*\*Rationale:|\n##|$)/)?.[1]?.trim() ?? "";
      const rationale = content.match(/\*\*Rationale:\*\*\s*(.*)/)?.[1] ?? "";
      blocks.push(
        `Rule: ${ruleName}\n` +
        `Applies to: ${appliesTo}\n` +
        `Correct pattern: ${example}\n` +
        `Rationale: ${rationale}`
      );
    } catch {
      // Best-effort — skip unreadable files
    }
  }
  return blocks.length > 0 ? "\n--- rule guidance ---\n" + blocks.join("\n\n") : "";
}

/**
 * Extract failing rule IDs from lint output. Best-effort heuristic.
 */
function extractFailingRules(lintOutput: string): string[] {
  const rules = new Set<string>();
  // ESLint format: rule-name (at end of line)
  for (const m of lintOutput.matchAll(/\b([\w-]+\/[\w-]+|[\w-]+)\s*$/gm)) {
    if (m[1] && m[1].length > 2 && !/^\d+$/.test(m[1])) rules.add(m[1]);
  }
  // Ruff format: E123, W456, etc.
  for (const m of lintOutput.matchAll(/\b([A-Z]\d{3,4})\b/g)) {
    rules.add(m[1]);
  }
  return Array.from(rules);
}

/**
 * Append one line to lint-failures.log. Dedup: skip if same rule+file
 * combination already logged on the same calendar day.
 */
function logLintFailure(filePath: string, ruleIds: string[], sessionId: string): void {
  const logPath = ".ai-layer/lint-rules/lint-failures.log";
  if (!existsSync(".ai-layer/lint-rules")) return;

  const today = new Date().toISOString().slice(0, 10);
  const rulesStr = ruleIds.join(",") || "unknown";
  const line = `${today} | ${filePath} | ${rulesStr} | ${sessionId}`;

  // Dedup check: read existing log and check for same date+file+rules
  if (existsSync(logPath)) {
    try {
      const existing = readFileSync(logPath, "utf8");
      const dedupKey = `${today} | ${filePath} | ${rulesStr}`;
      if (existing.includes(dedupKey)) return;
    } catch {
      // If we can't read, proceed to append
    }
  }

  try {
    appendFileSync(logPath, line + "\n");
  } catch {
    // Passive — never block on log failure
  }
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

        // Structured advisory output
        console.log(`\nGATE-1 ADVISORY: lint failed — ${label}`);
        console.log("\n--- lint output ---");
        console.log(result.output);

        // Rule guidance from .rules.md files
        const guidance = lookupRuleGuidance(result.output);
        if (guidance) {
          console.log(guidance);
        }

        console.log("\nSelf-correction: resolve each failure before the next write.");
        console.log("Retry budget: call scripts/retry-budget.sh before re-attempting.");

        // Passive failure log
        const ruleIds = extractFailingRules(result.output);
        logLintFailure(label, ruleIds, input.sessionID ?? "unknown");
      }
    },
  };
}
