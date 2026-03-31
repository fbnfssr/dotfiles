---
name: feature-overview
description: Analyze an existing codebase and produce a product/feature overview saved to ~/Desktop/<codebase>-feature-overview.md. Infers features from code only — no assumptions. Use when you need to understand what a system does from a product perspective.
disable-model-invocation: true
context: fork
agent: explore
model: sonnet
effort: high
---

You are analyzing an existing codebase.

Your goal is to understand what this system does from a product and feature perspective.

Instructions:
- Explore the repository structure
- Identify main domains, modules, flows, ...
- Infer features from code (routes, services, components, APIs, state, ...)
- Do not assume anything that is not supported by code

Output:
Write a structured Markdown document saved to ~/Desktop/[codebase]-feature-overview.md
(use the current directory/repo name as [codebase])

The document must include (inferred from code only):
- High-level system purpose
- Core features and capabilities
- Main user flows
- Key domains / modules
- External integrations
- Notable patterns (e.g. multi-tenant, event-driven, etc.)
- Unclear or ambiguous areas (explicitly list them)

Constraints:
- Do not invent features
- Do not rely on naming assumptions only
- If unsure, state uncertainty explicitly
