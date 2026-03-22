---
name: claudemd-audit
description: Audit the current project's CLAUDE.md against proven design principles for AI context files. Use when reviewing or improving a CLAUDE.md file, when onboarding onto a new project, or when evaluating the quality of a project's AI configuration.
context: fork
agent: explore
model: sonnet
allowed-tools: Read, Grep, Glob, LS, Bash
disable-model-invocation: true
---

# CLAUDE.md Audit

Audit the current project's CLAUDE.md against proven design principles for AI context files. Produce a structured report with findings and actionable suggestions.

## Procedure

1. Read the CLAUDE.md file at the project root. If it doesn't exist, report that and stop.
2. Read the project's `.claude/settings.json` if it exists, to understand what hooks are already configured.
3. Read `.husky/` or `.git/hooks/` directory if accessible, to understand what git hooks are in place.
4. Read the project's linting config (eslint.config.*, .eslintrc.*, biome.json, or similar) if accessible, to understand what lint rules are enforced mechanically.
5. Evaluate the CLAUDE.md against every principle below.
6. Output the report in the exact format specified at the end in a Markdown document in ~/Desktop.

## Evaluation Principles

### 1. Constraint programming, not documentation

Every rule in CLAUDE.md should be **checkable against a specific line of code or a specific action**. Vague aspirational statements like "write clean code," "follow best practices," or "keep things maintainable" are ineffective because the model has to invent a standard on the fly.

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
- Missing DO NOT rules for patterns the model is likely to reach for by default in this stack (e.g., StyleSheet in React Native, CommonJS in an ESM project, npm in a Yarn workspace)

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

If a pre-commit hook, CI gate, linter rule, or git hook already enforces something, putting the same rule in CLAUDE.md creates two places for drift with no benefit. CLAUDE.md should contain rules that **cannot** be encoded in a linter or hook: conventions requiring judgment, architectural constraints spanning files, workflow sequences that are non-obvious.

**Flag as issues:**
- Rules that duplicate what the project's linter already enforces (cross-reference with linting config if available)
- Rules that duplicate what hooks already enforce (cross-reference with hooks config if available)
- Checklist-style items that could be automated but aren't

### 8. Completeness for the stack

Based on the project's tech stack (inferred from package.json, Cargo.toml, requirements.txt, or similar), check whether common high-value rules for that stack are present.

**Flag as missing (if applicable to the stack):**
- Package manager constraints (which package manager to use, scoped installs for monorepos)
- Import/module conventions (barrel files, path aliases, layer boundaries)
- Styling conventions (CSS-in-JS approach, design token usage, component library rules)
- Testing conventions (file naming, test runner, coverage expectations)
- API/contract conventions (schema validation approach, DTO ownership, route structure)
- Environment and secret handling rules

## Output Format

```
# CLAUDE.md Audit Report

## Summary
- **File exists:** Yes/No
- **Total rules identified:** [count]
- **Checkable constraints:** [count] / [total] ([percentage])
- **Verdict:** [Strong / Adequate / Needs work / Weak]

## Critical Issues
[Issues that actively cause harm or wasted work. Each with:]
- **Issue:** [description]
- **Principle:** [which principle is violated]
- **Location:** [section or line reference in the file]
- **Suggestion:** [concrete fix]

## Warnings
[Issues that reduce effectiveness but don't cause direct harm. Same format.]

## Missing Content
[High-value content that is absent based on the project's stack and structure. Each with:]
- **Missing:** [what]
- **Why it matters:** [concrete consequence of absence]
- **Suggestion:** [what to add]

## Redundant Content
[Content that duplicates mechanical enforcement or adds no behavioral value. Each with:]
- **Content:** [what]
- **Already enforced by:** [linter/hook/CI that covers it]
- **Suggestion:** Remove or replace with a judgment-based constraint

## Rule Ordering Assessment
- **Current first section:** [what the file opens with]
- **Recommended first section:** [what should come first based on stakes]
- **Reordering needed:** Yes/No
- **Suggestion:** [specific reordering if needed]

## Strengths
[What the file does well — acknowledge good patterns to preserve them.]
```

## Constraints

- Do not modify any files. Produce a report only.
- Do not invent issues. If the CLAUDE.md is strong, say so.
- Be specific in every suggestion. "Add more rules" is not actionable. "Add a DO NOT rule for direct StyleSheet usage in screen components — the model defaults to StyleSheet.create in React Native projects" is actionable.
- If linting config or hooks are not accessible, note that the redundancy check is incomplete and skip that section rather than guessing.
