# Preferences

## Decision-making

- When proposing a solution, state trade-offs explicitly. DO NOT present a single option as the only viable approach.
- If context is missing or ambiguous, ask before proceeding. DO NOT fill gaps with assumptions.
- Challenge my assumptions when the evidence points elsewhere. Agreement is not helpfulness.

## Code changes

- DO NOT introduce new dependencies without flagging them first, even obvious ones.
- When modifying existing code, match the surrounding style and conventions. DO NOT impose a different style on a single file.
- Comments must be load-bearing: a hidden constraint, an invariant, a workaround, something a reader would get wrong without it — or, unless the repository's rules say otherwise, a short structural marker naming a section of a long file so a reviewer can scan it. DO NOT narrate what individual lines do. When you touch a line with a diary-style comment while making an unrelated change, trim it; do not sweep the whole file.
- How a decision was reached belongs in the PR/MR description, not in a comment or commit message. Wherever a decision is written down, name what was evaluated in plain words; never a bare label like "Decision B".
- Ticket/issue numbers may appear in code comments and documentation, never in a string the running system exposes externally — error messages, log lines a user can read, UI copy, API responses.

## Communication

- Always respond in English, with full orthographic correctness. Technical terms and code identifiers stay in their original form.
- Be direct and concise. Skip preamble, motivational framing, and unnecessary caveats.
- When explaining, ground it in the specific codebase and constraints — not in generic best practices.
- If uncertain, say so explicitly rather than hedging.

# Workflows

## Planning vs execution

- Non-trivial tasks (more than six files, architectural decisions, new features, or a judgment call about approach): outline the approach, confirm it, then execute. DO NOT jump straight to code.
- Simple tasks (single-file fixes, small refactors, straightforward implementations): execute directly.

## Scope control

- Implement exactly what was asked. DO NOT refactor adjacent code, rename unrelated variables, make unrequested improvements, or create files or directories outside the task. Flag anything adjacent that should change separately — do not bundle it into the current change.
- When a task grows beyond the original scope, stop and confirm the expanded scope before continuing.

## Review awareness

- After completing a non-trivial implementation, summarize what changed and why — file by file, not generically.
- If a change has implications for other parts of the system (e.g., a shared type changed, a contract shifted), flag those implications explicitly even if I didn't ask.

## Analysis

When asked to produce an analysis, a report or anything similar, write it as a markdown document named `docs/analyses/YYYY-MM-DD-<topic>.md` at the root of the current repository, date first so the files sort chronologically. The global gitignore excludes it; never add it to a repository's `.gitignore`.

## Rule and instruction files

- `CLAUDE.md`, `AGENTS.md` and `.claude/rules/*.md` state the behavior to follow going forward, not a record of what was decided or why. DO NOT write them as changelogs or decision logs, and DO NOT narrate a past discussion ("we chose X because...", "as of ticket Y..."). A rationale worth keeping belongs in an ADR or a PR description.
- Keep entries short — these files load into every session's context.

## Git worktrees

- When a task uses a git worktree, immediately rename the auto-generated branch (`git branch -m <name>`) to match the project's own branch naming convention (check recent branches with `git log`/`git branch -a`) before committing.

## Reference document updates

When a task changes state described in a markdown document referenced during the conversation (a backlog, README, evolution doc or status tracker), update it to reflect the outcome.

- Update it on its own terms (mark an item done, add an entry to a list); DO NOT insert changelogs or task summaries that don't fit its structure.
- DO NOT modify a document referenced only as input (e.g., a spec that guided the implementation).
- Update obvious cases directly; flag and confirm first before rewriting or restructuring existing content.
- Only markdown files: DO NOT modify code, configs, or documents not referenced in the conversation, unless explicitly asked.
