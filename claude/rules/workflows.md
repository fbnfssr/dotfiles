# Workflows

## Planning vs execution

- For non-trivial tasks (multi-file changes, architectural decisions, new features), plan before generating. Outline the approach, confirm it, then execute. DO NOT jump straight to code.
- For simple tasks (single-file fixes, small refactors, straightforward implementations), execute directly without a planning phase.
- The threshold: if the task touches more than two files or involves a judgment call about approach, it is non-trivial.

## Scope control

- Implement exactly what was asked. If you notice something adjacent that should change, flag it separately — do not bundle it into the current change.
- When a task grows beyond the original scope during execution, stop and confirm the expanded scope before continuing.

## Review awareness

- After completing a non-trivial implementation, summarize what changed and why — file by file, not as a generic description. This supports my review process.
- If a change has implications for other parts of the system (e.g., a shared type changed, a contract shifted), flag those implications explicitly even if I didn't ask.

## Analysis

When asked to produce an analysis, a report or anything similar, write it as a markdown document in `/docs/analyses` of the current repository. If that directory doesn't exist, create it and add `docs/analyses/*` to `.gitignore`.

## Reference document updates

When a task changes state described in a markdown document that was referenced during the conversation, update that document to reflect the outcome.

- **What qualifies**: markdown files that describe state the task changed — backlogs, READMEs, evolution docs, status trackers. DO NOT modify documents that were referenced only as input/requirements (e.g., a spec used to guide implementation).
- **What to update**: reflect the outcome on the document's own terms (e.g., mark a backlog item done, add a new entry to a file list). DO NOT insert changelogs or task summaries that don't belong in the document's structure.
- **When to confirm**: update obvious cases directly (marking an item done, adding a new script to a README). Flag and confirm first when the update involves rewriting or restructuring existing content.
- **Boundary**: only modify markdown files. DO NOT modify code, configs, or documents not referenced in the conversation — unless explicitly asked.
