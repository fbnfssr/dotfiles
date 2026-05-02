---
name: claudemd-audit
description: Audit the current project's Claude Code memory configuration — CLAUDE.md, .claude/rules/, @imports, and settings — against proven design principles for AI context files. Use when reviewing or improving a project's AI configuration, when onboarding onto a new project, or when evaluating the quality of a project's Claude Code setup.
context: fork
agent: explore
model: sonnet
allowed-tools: Read, Grep, Glob, LS, Bash
disable-model-invocation: true
---

# Claude Code Memory Audit

Audit the current project's Claude Code memory configuration against proven design principles. Produce a structured report with findings and actionable suggestions.

The audit covers the full project-level memory system: CLAUDE.md files, `.claude/rules/` rule files, `@` imports, and `.claude/settings.json`. User-level configuration (`~/.claude/CLAUDE.md`) and auto memory (`MEMORY.md`) are out of scope — this is a project audit.

## Procedure

### Phase 1: Discovery

1. Check for a CLAUDE.md at the project root (`./CLAUDE.md`). Also check `./.claude/CLAUDE.md`. Either or both may exist.
   - If neither exists, report that and stop.
2. Measure the line count of each discovered CLAUDE.md file.
3. Scan for `@` import references inside every discovered CLAUDE.md. For each `@path/to/file` reference:
   - Check whether the referenced file exists on disk.
   - Note the import (file path, exists yes/no).
   - Do NOT follow imports into `~/` (user-level, out of scope).
4. Check for `CLAUDE.local.md` at the project root. Note whether it exists.
5. Scan `.claude/rules/` if it exists. For each `.md` file found:
   - Check whether it has a `paths:` YAML frontmatter block (path-scoped rule) or not (unconditional rule).
   - Measure its line count.
   - Note any symlinks.
6. Spot-check for subdirectory CLAUDE.md files. In a monorepo, check immediate child directories of the root (e.g., `packages/*/CLAUDE.md`, `apps/*/CLAUDE.md`). Note which exist.
7. Read `.claude/settings.json` if it exists, to understand hooks and other configuration.
8. Read `.husky/` or `.git/hooks/` directory if accessible, to understand what git hooks are in place.
9. Read the project's linting config (`eslint.config.*`, `.eslintrc.*`, `biome.json`, or similar) if accessible.

### Phase 2: Evaluation

Evaluate all discovered memory files against every principle below. Apply principles to the memory system as a whole, not just the root CLAUDE.md in isolation.

### Phase 3: Report

Output the report in the exact format specified at the end, as a Markdown document saved to `/docs/analyses/reports`. If directories don't exist create them and add `docs/analyses/*` to `.gitignore`.

## Evaluation Principles

### 1. Constraint programming, not documentation

Every rule in a memory file should be **checkable against a specific line of code or a specific action**. Vague aspirational statements like "write clean code," "follow best practices," or "keep things maintainable" are ineffective because the model has to invent a standard on the fly.

**Flag as issues:**
- Statements that describe goals rather than constraints
- Rules that cannot be verified against a concrete output
- Philosophy paragraphs that don't resolve to an actionable constraint

### 2. Attention decay and rule ordering

Models weight content near the top of the file more heavily than content in the middle or bottom. The highest-stakes rules — those that, if violated, cause real damage or significant wasted work — must be in the first section of the file.

**Flag as issues:**
- Critical rules (architectural boundaries, forbidden patterns, security constraints) buried after less important content
- The file opening with project descriptions, philosophy, or onboarding material before any rules
- "Important" or "Critical" sections appearing past the halfway point of the file

### 3. DO NOT / DO pattern

Stating what not to do intercepts the model's default behavior. Stating what to do competes with it. The most effective rules use both: a DO NOT to block the wrong path and a DO to direct toward the right one.

**Flag as issues:**
- Rules that only state what to do without blocking the common wrong alternative
- Missing DO NOT rules for patterns the model is likely to reach for by default in this stack (e.g., `StyleSheet` in React Native, CommonJS in an ESM project, `npm` in a Yarn workspace)

### 4. Command references

Exact command invocations in context eliminate an entire class of drift: wrong flags, wrong package manager, wrong workspace targeting, wrong test runner. Projects with monorepo conventions, custom dev workflows, or non-obvious test commands should treat command references as load-bearing.

**Flag as issues:**
- No command reference section when the project uses a monorepo, custom scripts, or non-standard tooling
- Incomplete command references (e.g., how to lint but not how to test, how to build but not how to run)
- Commands that reference tools or scripts without showing the exact invocation

### 5. File structure tree

Models don't have a mental map of the repository. A tree diagram hands them that map upfront and dramatically reduces speculative file-reading and wrong-path assumptions.

**Flag as issues:**
- No file structure section in projects with non-trivial directory organization
- File structure that is clearly outdated (references directories or files that don't exist)
- Overly deep trees that include every file instead of focusing on structural directories

### 6. Explain the why behind constraints

Rules with rationale get followed correctly at the edges because the model can infer intent. Rules without rationale get followed literally, and the model will violate the spirit whenever the literal rule doesn't quite fit.

**Flag as issues:**
- Rules stated without any rationale
- Rules where the rationale is generic (e.g., "for consistency") rather than explaining the actual consequence of violation

### 7. Don't duplicate mechanical enforcement

If a pre-commit hook, CI gate, linter rule, git hook, or `.claude/settings.json` hook already enforces something, putting the same rule in CLAUDE.md creates two places for drift with no benefit. CLAUDE.md and rule files should contain rules that **cannot** be encoded in a linter or hook: conventions requiring judgment, architectural constraints spanning files, workflow sequences that are non-obvious.

**Flag as issues:**
- Rules that duplicate what the project's linter already enforces (cross-reference with linting config if available)
- Rules that duplicate what hooks already enforce (cross-reference with `.claude/settings.json` hooks and `.husky/` or `.git/hooks/`)
- Checklist-style items that could be automated but aren't

### 8. Completeness for the stack

Based on the project's tech stack (inferred from `package.json`, `Cargo.toml`, `requirements.txt`, or similar), check whether common high-value rules for that stack are present — in the root CLAUDE.md, in `.claude/rules/`, or in imported files.

**Flag as missing (if applicable to the stack):**
- Package manager constraints (which package manager to use, scoped installs for monorepos)
- Import/module conventions (barrel files, path aliases, layer boundaries)
- Styling conventions (CSS-in-JS approach, design token usage, component library rules)
- Testing conventions (file naming, test runner, coverage expectations)
- API/contract conventions (schema validation approach, DTO ownership, route structure)
- Environment and secret handling rules

### 9. Modularity and file size

Claude Code's official guidance recommends CLAUDE.md files stay under 200 lines. Files over 200 lines consume more context and reduce adherence. Two mechanisms exist for splitting: `@path/to/file` imports (for referenced documentation, external guides, or detailed specs) and `.claude/rules/` files (for domain-specific constraints that benefit from path scoping).

A monolithic CLAUDE.md that tries to cover everything — project description, commands, architecture, coding style, testing rules, API conventions — in one file is a design smell.

**Flag as issues:**
- Any single memory file exceeding 200 lines
- A root CLAUDE.md covering multiple distinct domains (e.g., frontend patterns AND backend conventions AND CI/CD workflow) without splitting into rule files or using `@` imports
- No use of `@` imports or `.claude/rules/` when the CLAUDE.md is long and covers diverse topics
- Detailed documentation inlined in CLAUDE.md that could be referenced via `@` import (e.g., a full API reference, a lengthy style guide)

### 10. Rule scoping

`.claude/rules/` files can be scoped to specific file patterns using `paths:` YAML frontmatter. Path-scoped rules only activate when Claude reads files matching the pattern, saving context tokens and improving adherence for the rules that actually matter in the current editing context.

Projects with clearly distinct domains (e.g., `src/api/`, `src/components/`, `src/workers/`, `tests/`) benefit from path-scoped rules. Loading API convention rules when editing a React component wastes context.

**Flag as issues:**
- `.claude/rules/` files covering domain-specific concerns without `paths:` frontmatter (they load unconditionally even when irrelevant)
- No `.claude/rules/` directory when the project has distinct domains that would benefit from scoped rules
- `paths:` patterns that are too broad (e.g., `**/*` matches everything, defeating the purpose) or too narrow (e.g., exact file names that will break on rename)

**Do NOT flag as issues:**
- Small projects with a short CLAUDE.md that doesn't need splitting — rules scoping is a scaling mechanism, not a universal requirement
- Unconditional rules that genuinely apply to all files (code style, commit conventions, architectural boundaries)

### 11. Import hygiene

`@path/to/file` imports in CLAUDE.md expand and load at launch alongside the file that references them. They support relative and absolute paths, resolve relative to the importing file (not the working directory), and can recurse up to 5 levels deep.

**Flag as issues:**
- `@` imports referencing files that don't exist on disk (broken imports)
- Content duplicated between CLAUDE.md and an imported file (the import should replace the inline content, not repeat it)
- Deep import chains (approaching 5 hops) that make it hard to understand what gets loaded
- `@` imports referencing large files that shouldn't be fully loaded at launch (e.g., an entire codebase README when only a section is relevant)

**Do NOT flag if:**
- No `@` imports exist and the CLAUDE.md is under 200 lines — imports aren't needed for small files

## Output Format

```
# Claude Code Memory Audit Report

## Summary
- **Project:** [project name if identifiable]
- **Root CLAUDE.md:** [exists at ./CLAUDE.md / ./.claude/CLAUDE.md / both / neither]
- **CLAUDE.local.md:** [exists / not found]
- **Rule files (.claude/rules/):** [count] ([count] unconditional, [count] path-scoped)
- **@ imports found:** [count] ([count] valid, [count] broken)
- **Subdirectory CLAUDE.md files:** [count and locations, or "none found"]
- **Total lines across all memory files:** [count]
- **Total rules identified:** [count]
- **Checkable constraints:** [count] / [total] ([percentage])
- **Verdict:** [Strong / Adequate / Needs work / Weak]

## Critical Issues
[Issues that actively cause harm or wasted work. Each with:]
- **Issue:** [description]
- **Principle:** [which principle is violated]
- **File:** [which memory file contains the issue]
- **Location:** [section or line reference in the file]
- **Suggestion:** [concrete fix]

## Warnings
[Issues that reduce effectiveness but don't cause direct harm. Same format.]

## Missing Content
[High-value content that is absent based on the project's stack and structure. Each with:]
- **Missing:** [what]
- **Why it matters:** [concrete consequence of absence]
- **Suggestion:** [what to add and where — root CLAUDE.md, a rule file, or an imported file]

## Redundant Content
[Content that duplicates mechanical enforcement or adds no behavioral value. Each with:]
- **Content:** [what]
- **Already enforced by:** [linter/hook/CI/settings.json hook that covers it]
- **Suggestion:** Remove or replace with a judgment-based constraint

## Memory Architecture Assessment
- **Current structure:** [monolithic / partially modular / well-modularized]
- **Total memory files:** [count]
- **Largest file:** [filename] ([line count] lines)
- **Files over 200 lines:** [list or "none"]
- **Path-scoped rules in use:** Yes/No
- **@ imports in use:** Yes/No
- **Assessment:** [description of how well the project uses the layered memory system]
- **Suggestion:** [specific structural improvements if needed, e.g., "Extract the API conventions section (lines 85-140 of CLAUDE.md) into .claude/rules/api-conventions.md with paths: src/api/**/*.ts"]

## Rule Ordering Assessment
- **Current first section:** [what the file opens with]
- **Recommended first section:** [what should come first based on stakes]
- **Reordering needed:** Yes/No
- **Suggestion:** [specific reordering if needed]

## Strengths
[What the memory configuration does well — acknowledge good patterns to preserve them.]
```

## Constraints

- Do not modify any project files. Produce a report only.
- Do not invent issues. If the memory configuration is strong, say so.
- Be specific in every suggestion. "Add more rules" is not actionable. "Add a DO NOT rule for direct StyleSheet usage in screen components — the model defaults to StyleSheet.create in React Native projects" is actionable. "Extract API rules into .claude/rules/api.md with `paths: src/api/**/*.ts`" is actionable.
- If linting config or hooks are not accessible, note that the redundancy check is incomplete and skip that section rather than guessing.
- Evaluate the memory system as a whole. A rule might be in the right place in `.claude/rules/` even if it's not in the root CLAUDE.md — that's correct, not missing.
- Do not penalize small projects for not using `.claude/rules/` or `@` imports if their CLAUDE.md is concise and under 200 lines. Modularity is a scaling mechanism, not a universal requirement.
