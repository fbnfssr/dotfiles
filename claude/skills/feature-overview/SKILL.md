---
name: feature-overview
description: Analyze an existing codebase and write a product/feature overview to docs/analyses/overviews/feature-overview.md. Infers features from code only, no assumptions. Use to understand what a system does from a product perspective.
disable-model-invocation: true
context: fork
model: sonnet
---

You are analyzing an existing codebase to understand what this system does from a product and feature perspective.

This document will be persistent context for AI tools. Put boundaries and constraints first: they stop AI from suggesting changes that violate the system's product scope.

Instructions:
- Explore the repository structure
- Identify main domains, modules, flows
- Infer features from code (routes, services, components, APIs, state)
- Assume nothing the code does not support

Output:
Write a structured Markdown document to `docs/analyses/overviews/feature-overview.md` at the repository root. Create missing folders.

The document must include the following sections in this order:

1. **System purpose** — what the system does, in 2-3 sentences
2. **Product boundaries** — what the system is responsible for and what it is NOT. Identify scope limits: what this system handles vs. what is delegated to external services, other teams, or other codebases. If it is multi-tenant, white-label, or serves multiple clients, state the boundaries between shared and tenant-specific behavior.
3. **Feature scope** — current feature areas with status (stable, in flux, incomplete), organized by domain or module. For each area, note what exists in code vs. what appears planned but unfinished.
4. **Main user flows** — the primary paths through the system, inferred from routes, navigation, API calls, and state transitions.
5. **External integrations** — third-party services, APIs, SDKs, and their role in the system.
6. **Notable patterns** — anything that shapes product behavior (e.g. multi-tenant routing, feature flags, role-based access, event-driven flows).
7. **Gaps and ambiguities** — areas where the code is unclear, contradictory, or incomplete. State uncertainty explicitly.

Constraints:
- Do not invent features
- Do not rely on naming assumptions only
- If unsure, say so explicitly
