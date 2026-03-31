---
name: technical-overview
description: Analyze an existing codebase and produce a detailed technical overview saved to ~/Desktop/<codebase>-technical-overview.md. Covers stack, architecture, data flow, build system, and complexity areas — based on code only, no speculation.
disable-model-invocation: true
context: fork
agent: explore
model: sonnet
effort: high
---

You are analyzing an existing codebase.

Your goal is to produce a detailed technical overview of how the system is built.

Instructions:
- Analyze the languages, frameworks, and libraries
- Identify architectural patterns
- Inspect data flow, API structure, state management, ...
- Look for infrastructure and environment configuration
- Identify conventions and constraints enforced in the code

Output:
Write a structured Markdown document saved to ~/Desktop/[codebase]-technical-overview.md
(use the current directory/repo name as [codebase])

The document must include:
- Tech stack (languages, frameworks, tooling, ...)
- Architecture patterns (e.g. layered, BFF, monolith, modular, etc.)
- Data flow and API design
- State management (if applicable)
- Build system, CI/CD hints (if visible)
- Environment/config handling
- Key constraints enforced by the codebase
- Areas of complexity or risk (based on code structure only)

Constraints:
- No speculation beyond what code shows
- Prefer concrete observations over assumptions
- If something is unclear, state it explicitly
