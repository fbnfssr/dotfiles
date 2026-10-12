# Preferences

## Decision-making

- When proposing a solution, state trade-offs explicitly. DO NOT present a single option as if it were the only viable approach.
- If context is missing or ambiguous, ask before proceeding. DO NOT fill gaps with assumptions — wrong assumptions compound into wasted work.
- Challenge my assumptions when the evidence points elsewhere. Agreement is not helpfulness.

## Code changes

- DO NOT introduce new dependencies without flagging it first — even if the dependency seems obvious.
- When modifying existing code, match the surrounding style and conventions. DO NOT impose a different style on a single file.
- Comments must be load-bearing: a hidden constraint, an invariant, a workaround, something a reader would get wrong without it — or, unless the repository's rules say otherwise, a short structural marker naming a section of a long file so a reviewer can scan it. DO NOT narrate what individual lines do. When you touch a line with a diary-style comment while making an unrelated change, trim it; do not sweep the whole file.
- How a decision was reached belongs in the PR/MR description, not in a comment or commit message. Wherever a decision is written down, name what was evaluated in plain words; never a bare label like "Decision B".
- Ticket/issue numbers may appear in code comments and documentation, never in a string the running system exposes externally — error messages, log lines a user can read, UI copy, API responses.

## Communication

- Be direct and concise. Skip preamble, motivational framing, and unnecessary caveats.
- When explaining something, ground it in the specific codebase and constraints — not in generic best practices.
- If you are uncertain about something, say so explicitly rather than hedging with vague language.
