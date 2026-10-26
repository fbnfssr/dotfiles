---
name: claude-setup-audit
description: Audit the project's Claude Code setup (CLAUDE.md, rules, skills, agents, hooks, settings, MCP, other AI clients' files), then apply the changes you approve. Use when reviewing or improving a project's AI configuration or onboarding onto a project.
argument-hint: '[skip wording]'
allowed-tools: Read, Grep, Glob, Bash
disable-model-invocation: true
---

# Claude Code Setup Audit

Audit the project's Claude Code setup against the principles below, propose fixes and decisions, and apply what the user approves.

Scope: memory files (CLAUDE.md, CLAUDE.local.md, `.claude/rules/`, `@` imports), skills and commands, agents, hooks, settings and permissions, MCP servers, and other AI clients' instruction files (`AGENTS.md`, `.agents/`, `.codex/`) when they exist. User-level configuration (`~/.claude/`) and auto memory are out of scope.

## Procedure

Modify nothing before the user approves, except in the wording pass (Phase 2) and the report.

### Phase 1: Discovery

1. Root file: `./CLAUDE.md`, `./.claude/CLAUDE.md` or both. If neither exists, Claude Code reads `./AGENTS.md` instead: treat it as the root file. If none of the three exists, record that as a finding.
2. Record the line count and size in bytes of every file in scope. Size guidance counts lines; context cost follows bytes.
3. Memory: the `@path` imports in each CLAUDE.md and whether each target exists (imports resolve relative to the importing file; do not follow them into `~/`); whether `CLAUDE.local.md` exists; CLAUDE.md files in immediate child directories (in a monorepo, `apps/*/CLAUDE.md`, `packages/*/CLAUDE.md`).
4. Rules: for each `.md` file in `.claude/rules/`, whether it is path-scoped (`paths:` frontmatter) or unconditional, and whether it is a symlink. For each `paths:` pattern, count the tracked files it matches (`git ls-files ':(glob)<pattern>'`, expanding `{a,b}` braces by hand) and sample a few.
5. Skills (`.claude/skills/*/SKILL.md` with their supporting files, `.claude/commands/`) and agents (`.claude/agents/*.md`): frontmatter, description length, and whether each skill is model-invocable.
6. Runtime evidence: the `agentType` and `model` recorded for this project's past skill forks and subagents, in `~/.claude/projects/<main checkout path with each / replaced by ->*/*/subagents/agent-*.meta.json` (the trailing `*` also matches the project's worktrees). Group the runs by the first word of `description`, which names the skill or task.
7. Settings: `.claude/settings.json` (hooks, permissions, `claudeMdExcludes`, other keys); whether `.claude/settings.local.json` exists and is untracked; `.mcp.json`; the registered hook scripts and their tests.
8. Enforcement: git hooks (`.husky/` or `.git/hooks/`), CI workflows (`.github/workflows/` or similar), and the lint config (`eslint.config.*`, `.eslintrc.*`, `biome.json` or similar).
9. Other clients: `AGENTS.md`, `.agents/skills/` (whether each link resolves), `.codex/` (agents, hooks, config).
10. References: check that every command, script, file and directory the instruction files name exists (`package.json` scripts, paths). A name missing from the scripts may be a package binary (`yarn commitlint`), and a missing path may be gitignored or generated: confirm before flagging.
11. A documented procedure for changing the project's AI setup (a rule, skill or runbook), to follow in Phase 5, and whether instruction files are generated from a source (a marker comment, a sync script). Audit and edit the source, never the generated copy.

### Phase 2: Wording pass

Skip it when the invocation says so. Shorten the phrasing of every instruction file in scope without removing a rule, condition, exception or consequence. Leave frontmatter keys, code blocks, commands and paths unchanged.

- Start from a clean working tree that no other session uses; if the checkout is shared, work in a git worktree.
- With more than a few files, delegate: one subagent per file group (rules, skills, agents, other clients) with model `sonnet` and effort `low`, editing in place and listing its changes in its final message. Name the generated files each worker must leave alone.
- Review each file's `git diff --word-diff` and restore what was lost: dropped clauses, shifted meaning, a list split by a blank line, broken formatting. Regenerate generated files and run the project's checks for its AI setup.
- Report the bytes saved and what you restored, then wait for the user's review.

### Phase 3: Analysis

Evaluate everything against the principles below, as one system: a rule that lives in a `.claude/rules/` file instead of the root CLAUDE.md is placed correctly, not missing. Classify each finding as a fix (one viable change, no policy change) or a decision (several viable options, or a rule stops applying somewhere).

Write the report in the Output Format below to `docs/analyses/YYYY-MM-DD-claude-setup-audit.md` in the main checkout (the first entry of `git worktree list`), even when working in a worktree.

### Phase 4: Approval

Summarise the fixes and present each decision with its options and recommendation. Wait for the user's answers.

### Phase 5: Apply and verify

1. Apply the approved fixes and the chosen options, following the procedure from discovery step 11 when there is one.
2. Verify:
   - each `paths:` change, by listing the matching files before and after
   - the project's own checks for its AI setup (doc checks, hook tests), and the formatting of edited files
   - agent definitions, which load at session start: test an edited agent in a new session, or report it as untested
3. Record each decision's outcome in the report's Outcome section.
4. Name every policy change (a rule that stops applying somewhere) so the commit or PR description states it.

## Principles

### Memory files

#### 1. Constraints, not documentation

Every rule should be **checkable against a specific line of code or a specific action**. Vague aspirations ("write clean code", "follow best practices", "keep things maintainable") make the model invent a standard on the fly. Test each line: would removing it cause Claude to make mistakes? If not, it is a cut candidate.

**Flag:**
- Statements of goals rather than constraints
- Rules that can't be verified against a concrete output
- Philosophy paragraphs that don't resolve to an actionable constraint

#### 2. Direct instructions, sparing emphasis

State the expected action. Add a DO NOT only where the model's default in this stack is the wrong path, and pair it with the alternative. Emphasis (IMPORTANT, MUST, capitals, a bold **DO** or **DO NOT**) belongs on the line Claude keeps skipping: spread over many lines, none of it stands out.

**Flag:**
- Defaults the model reaches for in this stack with no rule redirecting them (e.g. `StyleSheet` in React Native, CommonJS in an ESM project, `npm` in a Yarn workspace)
- A DO NOT with no alternative
- Emphasis on most lines of a file or section

#### 3. Command references

Exact invocations eliminate a class of drift: wrong flags, package manager, workspace targeting or test runner. With monorepo conventions, custom workflows or non-obvious test commands, command references are load-bearing.

**Flag:**
- No command reference when the project uses a monorepo, custom scripts or non-standard tooling
- Incomplete references (how to lint but not test, how to build but not run)
- Tools or scripts named without their exact invocation

#### 4. Project map

Name only what names don't reveal: the purpose of each workspace or top-level area, and where a kind of code lives when directory names don't say. Claude lists directories and reads code itself; trees, file-by-file descriptions and dependency lists repeat what it can derive and go stale.

**Flag:**
- No map when the purpose of the top-level areas isn't obvious from their names
- Trees, file listings or dependency lists
- Entries for directories or files that don't exist

#### 5. Rationale where judgment is needed

A rule whose edges need judgment needs its reason, so the model can infer intent where the letter doesn't fit. The reason is the consequence of a violation, in a clause ("pre-commit rejects them"), not the history of the decision: how a rule was decided belongs in an ADR or PR description. A self-evident rule needs no rationale.

**Flag:**
- Rules whose edges need judgment and that give no reason
- Generic rationale ("for consistency") instead of the consequence of a violation
- Decision history, changelogs or narrated discussions ("we chose X because…", "as of ticket Y…")

#### 6. Don't duplicate mechanical enforcement

If a pre-commit hook, CI gate, linter rule, git hook or Claude Code hook enforces something, restating it in an instruction file creates two places to drift. Instruction files hold what a linter or hook can't encode: conventions requiring judgment, architectural constraints spanning files, non-obvious workflow sequences. Values copied from config (thresholds, lists, globs) belong in their source file, with the instruction pointing to it; keep only what the model needs before acting and can't derive from the source, such as a hook's known gaps.

The reverse also holds: instruction files are context, not enforcement. A costly, mechanically checkable never-do belongs in a hook, a `permissions.deny` rule, a lint rule or a CI gate.

**Flag:**
- Rules the linter already enforces (cross-reference the lint config)
- Rules hooks already enforce (cross-reference the hooks in `.claude/settings.json` and `.husky/` or `.git/hooks/`)
- Thresholds, lists or globs copied from a config file instead of pointing to it
- Checklist items that could be automated but aren't, and costly never-do rules with no enforcement (e.g. reading `.env` files)

#### 7. Completeness for the stack

From the tech stack (`package.json`, `Cargo.toml`, `requirements.txt` or similar), check whether the common high-value rules for it are present in the root CLAUDE.md, `.claude/rules/` or imported files.

**Flag as missing (if applicable):**
- Package manager constraints (which one, scoped installs in monorepos)
- Import/module conventions (barrel files, path aliases, layer boundaries)
- Styling conventions (CSS-in-JS approach, design tokens, component library rules)
- Testing conventions (file naming, test runner, coverage expectations)
- API/contract conventions (schema validation, DTO ownership, route structure)
- Environment and secret handling rules

#### 8. Size and modularity

Claude Code's guidance is to keep each CLAUDE.md under 200 lines: longer files consume more context and reduce adherence. Path-scoped `.claude/rules/` files and subdirectory CLAUDE.md files load only when needed. `@path` imports organise content but load at launch and cost the same as inline text.

A monolithic CLAUDE.md covering everything (project description, commands, architecture, coding style, testing, API conventions) is a design smell.

**Flag:**
- Any memory file over 200 lines
- A root CLAUDE.md covering several distinct domains (e.g. frontend patterns, backend conventions and CI/CD) without rule files or imports
- A long, multi-topic CLAUDE.md with no `@` imports or `.claude/rules/`
- Detailed documentation inlined in CLAUDE.md (a full API reference, a lengthy style guide) that belongs in a path-scoped rule or a document the file points to

#### 9. Rule scoping

A `.claude/rules/` file with `paths:` frontmatter loads only when Claude reads, writes or edits a matching file (including `cat` or `head` of one), which saves context and improves adherence where the rule matters. Patterns support globs and `{a,b}` braces. The rule arrives with the result of the tool call that triggered it, so the first Write of a new file is composed without it.

Projects with distinct domains (e.g. `src/api/`, `src/components/`, `src/workers/`, `tests/`) benefit from path-scoped rules: API conventions loading while editing a React component waste context.

**Flag:**
- Domain-specific rule files without `paths:` (they load unconditionally, even when irrelevant)
- No `.claude/rules/` when the project has distinct domains that would benefit from scoped rules
- Patterns that are too broad (`**/*` defeats the purpose; a styling rule matching every `.ts` file loads for API clients) or too narrow (exact file names that break on rename; test-file-only patterns, since the first new test file is written before its rule loads)

A narrower pattern stops the rule from applying somewhere: a suggestion to narrow lists sample files that would stop matching, and is a decision.

**Do NOT flag:** unconditional rules that genuinely apply to all files (code style, commit conventions, architectural boundaries).

#### 10. Import hygiene

`@path` imports load at launch with the file that references them. They accept relative and absolute paths, resolve relative to the importing file and recurse at most four hops.

**Flag:**
- Imports of files that don't exist
- Content duplicated between CLAUDE.md and an imported file (the import should replace the inline text)
- Import chains approaching four hops, which hide what gets loaded
- Imports of large files that shouldn't load in full at launch (e.g. a whole README when one section matters)

#### 11. No dead or stale instructions

Every instruction should change what the model does.

**Flag:**
- Instructions to read or apply a file already in context: CLAUDE.md in the main session or in an agent that loads it, a file the root already imports
- References to commands, scripts, files or directories that don't exist (discovery step 10)
- The same rule stated in several files

#### 12. Context cost by load time

What matters is what loads when:

- every session: root and ancestor CLAUDE.md files with their imports, unconditional rules, the descriptions of model-invocable skills and of agents, MCP tool names
- first touch of a file: path-scoped rules, subdirectory CLAUDE.md files
- on invocation: a skill's body; an agent's `skills:` preloads when it starts

Rewording tight files saves little; the large savings are structural.

**Flag:**
- A common edit (a screen, a handler, a test) that loads rules unrelated to it
- Every-session content that only some tasks need

### Skills and agents

#### 13. Bindings

Frontmatter decides what runs, with which model, tools and context. Check each value against what it does:

- `context: fork` runs the skill in a subagent; `agent:` and `model:` apply to that fork. `agent:` is case-sensitive: `explore` silently runs `general-purpose` instead of `Explore`.
- `Explore` and `Plan` cannot write and start without CLAUDE.md; `Explore` runs on the session model. `general-purpose` and custom agents load CLAUDE.md unless the agent sets `omitClaudeMd: true`.
- `allowed-tools` only pre-approves tools for the invoking turn; `disallowed-tools` (skills) and `tools` or `disallowedTools` (agents) restrict them.
- `disable-model-invocation: true` removes a skill from the listing and prevents an agent's `skills:` from preloading it.
- `skills:` in an agent injects each skill's full body when the agent starts.

**Flag:**
- Values that don't select what the file assumes: a wrong case, a read-only agent asked to write, `allowed-tools` relied on as a restriction
- Recorded runs (discovery step 6) whose `agentType` or `model` differs from the frontmatter
- Instructions the binding makes impossible or redundant

#### 14. One procedure per role

Each procedure lives in one place: a skill, or a supporting file that several skills reference. An agent that runs a procedure is a thin wrapper: it sets the model and limits and preloads the skill with `skills:`.

**Flag:**
- The same steps in an agent body and a skill, or in several skills
- Wrappers that restate their skill's rules
- Copies whose policies have diverged (one skips on failure, another writes a placeholder)

#### 15. Descriptions and listing cost

The description is how Claude picks a skill or delegates to an agent: what it does, then when to use it, key use case first. Every model-invocable skill's description and every agent's description load in every session. The skill listing is capped at 1% of the context window, and each entry at 1,536 characters.

**Flag:**
- Descriptions without a "when" clause, or with triggers that overlap another skill's
- Model-invocable skills that only the user runs (`disable-model-invocation: true` takes them out of the listing)
- A SKILL.md over 500 lines, or inlined reference material that a supporting file one level deep could hold

### Hooks, settings and MCP

#### 16. Hooks, permissions and servers

**Flag:**
- Hook registrations whose script is missing, and hook scripts without tests
- Broad `permissions.allow` entries in the shared `.claude/settings.json`; personal grants belong in `.claude/settings.local.json`, which stays untracked
- MCP servers in `.mcp.json` that no instruction, skill or agent uses

### Other clients

#### 17. Divergence from the Claude setup

When `AGENTS.md`, `.agents/` or `.codex/` exist, Claude Code's files are the reference: other clients' files may differ in mechanics, not in policy.

Claude Code reads `AGENTS.md` only when no CLAUDE.md exists. Content both clients need reaches Claude through an `@AGENTS.md` import (the documented pattern) or a copy kept equal by a check; clients without `@` imports, such as Codex, can't import CLAUDE.md.

**Flag:**
- CLAUDE.md and AGENTS.md sharing content with neither an import nor an equality check
- Shared skill links (`.agents/skills/` to `.claude/skills/`) that don't resolve, and client-native procedures whose policy diverges from the Claude version
- Hooks enforced in one client only, and other-client hooks that need an undocumented trust step
- Instructions telling a client to read a file it already loads (`AGENTS.md` in Codex)

## Output Format

```
# Claude Code Setup Audit Report

## Summary
- **Project:** [project name if identifiable]
- **Root file:** [./CLAUDE.md / ./.claude/CLAUDE.md / both / AGENTS.md only / none]
- **CLAUDE.local.md:** [exists / not found]
- **Rule files (.claude/rules/):** [count] ([count] unconditional, [count] path-scoped)
- **@ imports found:** [count] ([count] valid, [count] broken)
- **Subdirectory CLAUDE.md files:** [count and locations, or "none found"]
- **Skills:** [count] ([count] model-invocable) · **Agents:** [count]
- **Hooks:** [count registered] · **MCP servers:** [count]
- **Other clients:** [none / which files]
- **Memory files:** [lines] lines, [KB] KB
- **Wording pass:** [KB saved and items restored / skipped]
- **Verdict:** [Strong / Adequate / Needs work / Weak]

## Context Load
| Load | When | Size |
| ---- | ---- | ---- |
| [file or group of files] | [every session / first touch of a file such as <path> / on invocation] | [KB] |

## Critical Issues
[Fixes for issues that actively cause harm or wasted work. Each with:]
- **Issue:** [description]
- **Principle:** [which principle is violated]
- **File:** [path]
- **Location:** [section or line reference]
- **Fix:** [concrete change]

## Warnings
[Fixes for issues that reduce effectiveness without direct harm. Same format.]

## Missing Content
[High-value content absent given the project's stack and structure. Each with:]
- **Missing:** [what]
- **Why it matters:** [concrete consequence of absence]
- **Suggestion:** [what to add and where]

## Redundant Content
[Content that duplicates mechanical enforcement or adds no behavioural value. Each with:]
- **Content:** [what]
- **Already enforced by:** [the linter rule, hook, CI gate or settings entry that covers it]
- **Suggestion:** Remove, point to the source, or replace with a judgment-based constraint

## Decisions
[Findings with several viable options, or whose fix stops a rule from applying somewhere. Each with:]
- **Finding:** [description and location]
- **Options:** [each option with its trade-off]
- **Recommendation:** [option and why]

## Architecture Assessment
- **Current structure:** [monolithic / partially modular / well-modularized]
- **Largest file:** [path] ([lines] lines, [KB] KB)
- **Files over their size guidance:** [CLAUDE.md or rule over 200 lines, SKILL.md over 500, or "none"]
- **Path-scoped rules in use:** Yes/No
- **@ imports in use:** Yes/No
- **Duplicated procedures:** [list or "none"]
- **Assessment:** [how well the project uses memory layers, skills and agents]
- **Suggestion:** [specific structural improvements, e.g. "Extract the API conventions section (lines 85-140 of CLAUDE.md) into .claude/rules/api-conventions.md with paths: src/api/**/*.ts"]

## Strengths
[What the setup does well, so those patterns are preserved.]

## Outcome
[Filled in Phase 5: each decision's choice and what was applied.]
```

## Constraints

- Do not invent issues. If the setup is strong, say so.
- Be specific in every suggestion. "Add more rules" is not actionable. "Add a rule against StyleSheet.create in screen components that names the theming helper to use instead — the model defaults to StyleSheet.create in React Native projects" and "Extract API rules into .claude/rules/api.md with `paths: src/api/**/*.ts`" are.
- Rank structural findings (what loads where, duplicated procedures) above rewording.
- If the lint config, hooks or CI aren't accessible, say the enforcement check is incomplete and skip that section rather than guessing.
- Do not penalise small projects for not using `.claude/rules/`, `@` imports, skills or agents when their CLAUDE.md is concise and under 200 lines: modularity is a scaling mechanism, not a universal requirement.
