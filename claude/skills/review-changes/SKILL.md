---
name: review-changes
description: Review the current uncommitted and staged changes in a repository for correctness, effectiveness, performance, code duplication, and code best practices. Produces a structured report. Use when you want a thorough code review before committing or opening a PR.
context: fork
agent: explore
model: sonnet
allowed-tools: Read, Grep, Glob, Bash
disable-model-invocation: true
---

# Code Review: Current Changes

Review the current git diff (staged and unstaged changes) for quality issues. Produce a structured, actionable report. Do NOT modify any files.

## Procedure

### Phase 1: Gather the diff

1. Run `git diff HEAD` to capture all staged and unstaged changes relative to HEAD. If HEAD doesn't exist yet (initial commit), run `git diff --cached` instead.
2. Run `git status` to understand which files are new, modified, or deleted.
3. For each modified or new file in the diff, read the full file to understand its surrounding context — do not evaluate hunks in isolation.

### Phase 2: Understand the context

Before evaluating, orient yourself:
- What is the apparent purpose of the change? Infer it from the diff, commit message (if staged), or surrounding code.
- What layer of the system is affected (e.g., data model, business logic, API, UI, config, tests)?
- What language and framework conventions apply?

### Phase 3: Evaluate

Evaluate the diff against every dimension below. Apply findings only to lines that were actually changed or are directly implicated by the change — do not review the entire file.

#### 1. Correctness
- Logic errors, off-by-one errors, wrong conditions, broken edge cases.
- Null/undefined dereferences, missing guards, type mismatches.
- Mutations of inputs that callers don't expect.
- Incorrect assumptions about external behavior (APIs, DB results, file I/O).

#### 2. Effectiveness
- Does the change actually accomplish its stated purpose?
- Are there scenarios where the change would silently fail or produce wrong output?
- Missing return values, unhandled async paths, swallowed errors.

#### 3. Performance
- Expensive operations inside loops that could be hoisted.
- N+1 query patterns or unbounded DB/API calls.
- Unnecessary recomputation of derived values.
- Memory leaks: event listeners, subscriptions, timers not cleaned up.
- Large allocations or copies where a reference would suffice.

#### 4. Code duplication
- Logic duplicated from elsewhere in the same file or a nearby file.
- Patterns that already exist in a utility, helper, or library but are re-implemented.
- Constants or strings hardcoded multiple times that should be a single named value.

#### 5. Code clarity and maintainability
- Names that don't reflect the actual behavior of the variable/function.
- Deeply nested logic that could be flattened with early returns.
- Magic numbers or magic strings with no explanation.
- Large functions doing too many things — flag only when the change introduced or significantly expanded them.

#### 6. Security
- Injection risks: SQL, shell, HTML/XSS, path traversal.
- Secrets or credentials hardcoded or logged.
- Authentication/authorization checks missing on new or modified endpoints/operations.
- Input from untrusted sources used without validation or sanitization.
- Overly permissive CORS, CSP, or access control changes.

#### 7. Error handling
- Errors caught and silently dropped.
- Generic catch blocks that mask specific failure modes.
- Errors surfaced to users with internal details they shouldn't see.
- Missing cleanup (resources, locks, transactions) in error paths.

#### 8. Test coverage
- New logic added with no corresponding test changes.
- Tests that assert on irrelevant properties rather than the actual behavior under test.
- Tests that would pass even if the logic were broken (vacuous tests).
- Mocks that are set up but assert nothing meaningful.

#### 9. Consistency
- Style, naming, or structural conventions that differ from the surrounding code without a clear reason.
- Import ordering, file structure, or module organization that diverges from the project's established pattern.

## Output Format

Print the report directly in the chat. Do NOT write a file.

```
# Code Review

## Summary
- **Files changed:** [count]
- **Lines added / removed:** [+N / -N if available from git diff --stat]
- **Apparent purpose:** [1-2 sentence inference of what the change is trying to do]
- **Verdict:** [Approve / Approve with suggestions / Request changes]

## Critical Issues
[Issues that are likely bugs, security vulnerabilities, or would cause incorrect behavior in production.]

For each issue:
- **File:** `path/to/file.ext` (line N or lines N–M)
- **Issue:** [description]
- **Why it matters:** [concrete consequence]
- **Suggestion:** [specific fix — show the corrected code if short enough]

_None_ if no critical issues found.

## Warnings
[Issues that reduce quality, maintainability, or correctness under edge cases, but are not outright bugs.]

Same format as Critical Issues.

_None_ if no warnings found.

## Suggestions
[Low-priority observations: style, naming, minor improvements. Only flag if clearly non-trivial — do not nitpick.]

Same format, but shorter. Group related suggestions if there are many.

_None_ if nothing worth flagging.

## Strengths
[Acknowledge what is done well — clean abstractions, good test coverage, clear naming, etc. Be specific.]

## Testing gaps
[List specific behaviors introduced by the change that have no test coverage. If tests were added and coverage looks adequate, say so.]
```

## Constraints

- Do NOT modify any files. Produce a report only.
- Do NOT review lines that were not changed unless they are directly implicated (e.g., a function whose signature was changed but whose callers were not updated).
- Do NOT invent issues. If the change is clean, say so clearly.
- Be specific: cite file paths and line numbers for every finding. "This function is too long" is not actionable. "The `processOrder` function at line 42 of `orders.ts` now handles three distinct responsibilities — validation, DB write, and notification dispatch — consider splitting after the DB write" is actionable.
- If the diff is empty or there are no changes, say so and stop.
- Apply the relevant language and framework conventions — do not apply generic advice that conflicts with the project's established patterns.
