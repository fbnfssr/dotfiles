---
name: review-changes
description: Review uncommitted and staged changes for correctness, effectiveness, performance, duplication, and best practices, and produce a structured report. Use for a thorough code review before committing or opening a PR.
context: fork
model: sonnet
allowed-tools: Read, Grep, Glob, Bash
disable-model-invocation: true
---

# Code Review: Current Changes

Review the uncommitted changes (staged, unstaged and untracked) for quality issues and produce a structured, actionable report. Do NOT modify any files.

## Procedure

### Phase 1: Gather the diff

1. Run `git diff HEAD --stat` and `git diff HEAD` for all staged and unstaged changes. If HEAD doesn't exist yet (initial commit), use `--cached` instead of `HEAD`.
2. Run `git status` to see which files are new, modified, deleted or untracked. Review untracked files as new files.
3. Read each modified or new file in full; don't evaluate hunks in isolation.

### Phase 2: Understand the context

- Purpose of the change: infer it from the diff and surrounding code.
- Layer affected (e.g., data model, business logic, API, UI, config, tests).
- Applicable language and framework conventions.

### Phase 3: Evaluate

Evaluate the diff against every dimension below, only on changed lines or lines directly implicated by the change.

#### 1. Correctness
- Logic errors, off-by-one errors, wrong conditions, broken edge cases.
- Null/undefined dereferences, missing guards, type mismatches.
- Unexpected mutations of inputs.
- Wrong assumptions about external behavior (APIs, DB results, file I/O).

#### 2. Effectiveness
- Does the change accomplish its stated purpose?
- Scenarios where it silently fails or produces wrong output.
- Missing return values, unhandled async paths, swallowed errors.

#### 3. Performance
- Expensive operations inside loops that could be hoisted.
- N+1 query patterns or unbounded DB/API calls.
- Unnecessary recomputation of derived values.
- Memory leaks: listeners, subscriptions, timers not cleaned up.
- Large allocations or copies where a reference would suffice.

#### 4. Code duplication
- Logic duplicated elsewhere in the same or a nearby file.
- Re-implementation of an existing utility, helper, or library function.
- Constants or strings hardcoded multiple times instead of one named value.

#### 5. Code clarity and maintainability
- Names that don't reflect actual behavior.
- Deeply nested logic that early returns could flatten.
- Unexplained magic numbers or strings.
- Large functions doing too many things — flag only when the change introduced or significantly expanded them.

#### 6. Security
- Injection risks: SQL, shell, HTML/XSS, path traversal.
- Secrets or credentials hardcoded or logged.
- Missing authentication/authorization checks on new or modified endpoints/operations.
- Untrusted input used without validation or sanitization.
- Overly permissive CORS, CSP, or access control changes.

#### 7. Error handling
- Errors caught and silently dropped.
- Generic catch blocks that mask specific failure modes.
- Internal details exposed to users in errors.
- Missing cleanup (resources, locks, transactions) in error paths.

#### 8. Test coverage
- New logic with no corresponding test changes.
- Tests that assert irrelevant properties instead of the behavior under test.
- Vacuous tests that would pass even if the logic were broken.
- Mocks that are set up but assert nothing meaningful.

#### 9. Consistency
- Style, naming, or structural conventions that differ from the surrounding code without a clear reason.
- Import ordering, file structure, or module organization that diverges from the project's pattern.

## Output Format

Print the report in the chat.

```
# Code Review

## Summary
- **Files changed:** [count]
- **Lines added / removed:** [+N / -N from git diff --stat]
- **Apparent purpose:** [1-2 sentences]
- **Verdict:** [Approve / Approve with suggestions / Request changes]

## Critical Issues
[Likely bugs, security vulnerabilities, or incorrect production behavior.]

For each issue:
- **File:** `path/to/file.ext` (line N or lines N–M)
- **Issue:** [description]
- **Why it matters:** [concrete consequence]
- **Suggestion:** [specific fix, with corrected code if short]

_None_ if no critical issues found.

## Warnings
[Issues that reduce quality, maintainability, or edge-case correctness, but are not outright bugs.]

Same format as Critical Issues.

_None_ if no warnings found.

## Suggestions
[Low-priority, clearly non-trivial observations: style, naming, minor improvements. Do not nitpick.]

Same format, but shorter. Group related suggestions.

_None_ if nothing worth flagging.

## Strengths
[Specific things done well: clean abstractions, good test coverage, clear naming, etc.]

## Testing gaps
[Behaviors introduced by the change with no test coverage. If tests were added and look adequate, say so.]
```

## Constraints

- Report only; modify no files.
- Do NOT review unchanged lines unless directly implicated (e.g., a function whose signature changed but whose callers were not updated).
- Do NOT invent issues. If the change is clean, say so.
- Be specific: cite file paths and line numbers for every finding. "This function is too long" is not actionable; "`processOrder` at line 42 of `orders.ts` handles validation, DB write, and notification dispatch — consider splitting after the DB write" is.
- If there are no changes (empty diff, no untracked files), say so and stop.
- Apply the project's language and framework conventions; do not give generic advice that conflicts with its established patterns.
