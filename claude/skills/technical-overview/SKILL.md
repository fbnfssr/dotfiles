---
name: technical-overview
description: Analyze an existing codebase and produce a detailed technical overview saved to /docs/analyses/overviews/technical-overview.md. Covers stack, architecture, data flow, build system, and complexity areas — based on code only, no speculation.
disable-model-invocation: true
context: fork
agent: explore
model: sonnet
effort: high
---

You are analyzing an existing codebase.

Your goal is to produce a detailed technical overview of how the system is built.

This document will be used as persistent context for AI tools (Claude chat, Claude Code). Structure it so that architectural boundaries and enforced constraints appear first — these are what prevent AI from producing changes that violate the system's architecture.

Instructions:
- Analyze the languages, frameworks, and libraries
- Identify architectural patterns
- Inspect data flow, API structure, state management, ...
- Look for infrastructure and environment configuration
- Identify conventions and constraints enforced in the code

Output:
Write a structured Markdown document saved to `/docs/analyses/overviews/technical-overview.md`. If the `/docs/analyses/overviews/` folders don't exist, create them and add `docs/analyses/*` to `.gitignore`.

The document must include the following sections in this order:

1. **Architectural boundaries and constraints** — the rules this codebase enforces, inferred from code structure, linting config, module boundaries, import restrictions, build setup, and naming conventions. State what is NOT allowed as clearly as what is. Include: layer separation (what depends on what), module ownership, data isolation rules, and any enforced patterns (e.g. contracts-first, feature-flag gating, tenant isolation). This section is the highest-value context for AI consumption.
2. **Tech stack** — languages, frameworks, tooling, package manager, runtime versions (if detectable).
3. **Architecture patterns** — how the system is structured (e.g. layered, BFF, monolith, modular, event-driven). Include a high-level description of how modules/layers relate.
4. **Data flow and API design** — how data moves through the system. API patterns (REST, GraphQL, RPC), request/response flows, data transformation points.
5. **State management** — how state is handled across the system (client state, server state, caching, persistence). Skip if not applicable.
6. **Build system and CI/CD** — build tooling, scripts, CI configuration, deployment hints. Only what is visible in code.
7. **Environment and configuration** — how config is managed (env files, feature flags, tenant config, secrets handling).
8. **Tech debt and risk areas** — areas of complexity, fragility, or inconsistency observed in the code structure. Include: tightly coupled modules, unclear ownership, missing tests, outdated patterns, or anything that increases the cost of change.
9. **Conventions** — naming patterns, file organization rules, testing patterns, commit/PR conventions if visible.

Constraints:
- No speculation beyond what code shows
- Prefer concrete observations over assumptions
- If something is unclear, state it explicitly
- Lead with boundaries — they are the highest-value context for AI consumption
