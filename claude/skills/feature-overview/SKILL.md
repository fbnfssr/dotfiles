---
name: feature-overview
description: Analyze an existing codebase and produce a product/feature overview saved to /docs/analyses/overviews/feature-overview.md. Infers features from code only — no assumptions. Use when you need to understand what a system does from a product perspective.
disable-model-invocation: true
context: fork
agent: explore
model: sonnet
effort: high
---

You are analyzing an existing codebase.

Your goal is to understand what this system does from a product and feature perspective.

This document will be used as persistent context for AI tools (Claude chat, Claude Code). Structure it so that boundaries and constraints appear first — these are what prevent AI from producing suggestions that violate the system's product scope.

Instructions:
- Explore the repository structure
- Identify main domains, modules, flows, ...
- Infer features from code (routes, services, components, APIs, state, ...)
- Do not assume anything that is not supported by code

Output:
Write a structured Markdown document saved to `/docs/analyses/overviews/feature-overview.md`. If the `/docs/analyses/overviews/` folders don't exist, create them and add `docs/analyses/*` to `.gitignore`.

The document must include the following sections in this order:

1. **System purpose** — what this system does, in 2-3 sentences
2. **Product boundaries** — what the system is responsible for and what it is NOT. Identify scope limits: what is handled by this system vs. delegated to external services, other teams, or other codebases. If the system is multi-tenant, white-label, or serves multiple clients, state the boundaries between shared and tenant-specific behavior.
3. **Feature scope** — current feature areas with status (stable, in flux, incomplete). Organized by domain or module. For each area, note what exists in code vs. what appears planned but unfinished.
4. **Main user flows** — the primary paths through the system as inferred from routes, navigation, API calls, and state transitions.
5. **External integrations** — third-party services, APIs, SDKs, and their role in the system.
6. **Notable patterns** — anything that shapes product behavior (e.g. multi-tenant routing, feature flags, role-based access, event-driven flows).
7. **Gaps and ambiguities** — areas where the code is unclear, contradictory, or appears incomplete. State uncertainty explicitly.

Constraints:
- Do not invent features
- Do not rely on naming assumptions only
- If unsure, state uncertainty explicitly
- Lead with boundaries — they are the highest-value context for AI consumption
