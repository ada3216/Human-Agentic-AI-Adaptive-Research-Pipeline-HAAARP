---
name: summarize-decisions
agent: executor
---
Read .ai-layer/decisions.md in full.
Count all entries (lines beginning with "DATE:").
If fewer than 50 entries: output "decisions.md: [N] entries — no compaction needed." Stop.

If 50 or more entries:
  Identify all entries with dates older than 30 days from today.
  Produce one ARCHIVE block:
    DATE: [today ISO] | ARCHIVE | [N] entries before [cutoff date] summarized:
    [3–5 sentences covering: phases completed, key design decisions, escalations resolved]

  Write the new decisions.md: ARCHIVE block first, then all entries from the last 30 days verbatim.
  Do not modify any entry from the last 30 days.
  Append: DATE: [today] | COMPACTION | [N] entries archived.
  Report: "Compacted [N] entries. Consider reviewing .ai-layer/ARCHITECTURE.md — after this many decisions the project's actual patterns may have evolved beyond what ARCHITECTURE.md currently captures. Update manually or re-run /project-init."

## WORKFLOW-END COMMIT (mandatory after governed-file edits)

Before returning control, run this sequence:
1. `bash scripts/check.sh` — must exit 0 before proceeding
2. Stage only files this command wrote — use `git add <file>...`. Do NOT use `git add -A`.
3. `git status` — confirm what is staged matches the files this command wrote
4. `git commit -m "[type]([scope]): [description]"` to produce a clean git commit
5. `git status --porcelain` — if any listed files were written by this command, stop and fix. Unrelated dirty files are advisory only.
