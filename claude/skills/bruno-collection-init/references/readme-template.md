# `/bruno/README.md` Template

Use this as the scaffold for the human-facing README generated at `/bruno/README.md`. Fill in the project-specific pieces marked with `<...>`.

---

```markdown
# Bruno API Collection

This directory contains the project's API test collection, authored in Bruno's OpenCollection YAML format. It serves two purposes: an executable spec run in CI, and a browsable reference for engineers working on the backend.

For Claude-assisted edits, the maintenance rules are also encoded in the project `CLAUDE.md` under "Bruno API Collection Maintenance".

## Layout

- `opencollection.yml` — collection-level config: default headers, timeouts, and a `docs:` block that Bruno GUI renders as the collection landing page.
- `environments/` — one YAML per environment (`development`, `staging`, `production`, `CI`). Each declares `baseUrl` and any env-specific variables.
- `00-auth/` — login, registration (destructive), and an authenticated smoke request (`me.yml`) that verifies the `Authorization` header cascade works.
- `10-reference-data/` (or `10-setup/`) — read-only GETs whose job is to capture reference IDs for downstream creates (`firstCityId`, `firstBuildingTypeId`, …). Every capture is backed by an `isNotEmpty` assertion so an empty seed fails here, not in the consumer.
- `20-{domain}/`, `30-{domain}/`, … — feature domains. Numeric prefixes encode execution order: producer folders get lower prefixes than their consumers.
- `90-cleanup/` — teardown (logout, delete test data). Excluded from CI via `--exclude-tags=teardown`; runs last locally because the numeric prefix sorts after every feature folder.

Every `folder.yml` carries a folder-level `docs:` block and a folder-level response-time assertion. Every request file carries its own `docs:` block — the collection doubles as browsable API documentation.

### Authentication note

The collection sets the `Authorization` header via a **manual `headers:` entry in every authenticated folder's `folder.yml`**, not through OpenCollection's typed `auth:` block. The typed `auth: { type: bearer, token }` block is a known no-op in `@usebruno/cli` 3.2.x (issues #2326 and #3688) — it logs a silent stderr warning and sends no header. Folder-level `headers:` cascade correctly into requests; the CI workflow scrubs the header value from reports via `--reporter-skip-headers "Authorization"`.

If you need to bypass auth on a single request inside an otherwise-authenticated folder, strip the inherited header with a `before-request` script: `req.deleteHeader("Authorization")`.

## Requirements

- Node.js (>= 20 recommended)
- Bruno CLI: `npm install -g @usebruno/cli`
- Bruno GUI (optional, for visual exploration): <https://www.usebruno.com/>

## Before the first run

1. Start the local API server (`<project-specific start command>`).
2. Seed the database with the reference fixtures the collection expects (`<project-specific seed command>`).
3. Ensure a test user exists with known credentials. The collection's `Development` environment declares the expected username/password in its `variables:` block — align the seed to match, or override at runtime via `--env-var`.

## Running locally

```bash
# From the repo root:
cd bruno

# Default suite — excludes destructive/manual/teardown, same as CI
bru run --env Development --exclude-tags=destructive,manual,teardown

# Full suite INCLUDING destructive/manual/teardown (local only — creates real data)
bru run --env Development

# A single folder
bru run users --env Development

# Smoke-tagged requests only
bru run --env Development --tags=smoke

# Skip error-case requests
bru run --env Development --exclude-tags=error-case

# Generate a local HTML report
bru run --env Development --reporter-html results.html
```

## Tag reference

| Tag | Meaning | In default run? |
|-----|---------|-----------------|
| `{domain}` | Domain of the endpoint. Every request gets one. | Yes |
| `smoke` | Critical-path happy request. | Yes |
| `error-case` | Validation / 401 / 404 scenario. | Yes |
| `destructive` | Non-idempotent writes, seeds real data, hits third-party services. | **No** |
| `manual` | Requires out-of-band input (emailed token, 2FA code). | **No** |
| `contract` | Liveness-only check on a list endpoint whose creator is `destructive`-tagged. In CI the list is empty; "returned 200" proves the route is still registered, nothing more. | Yes |
| `teardown` | Lives in `90-cleanup/`. Revokes state — logout, delete test data. | **No** — excluded from CI by default. |
| `auth-chain` | Multi-step auth flows like `refresh-token.yml` that don't need to fire on every suite run. | **No** — run explicitly via `bru run 00-auth --tags=auth-chain`. |

## Adding a new endpoint

1. Pick the numbered domain folder under `/bruno/` (create one if new; add a `folder.yml` with a `docs:` block and a folder-level response-time assertion). Choose the folder's numeric prefix by where it falls in the capture-dependency graph: producers use lower numbers than their consumers. After adding a new folder, run `ls /bruno/` and confirm the order still matches the dependency graph.
2. Add a request file named `{verb}-{resource}.yml` (e.g. `create-order.yml`).
3. Give it an incrementing `seq` within the folder — 1–9 for happy path, 10+ for error cases.
4. Write a `docs:` block at the top of the request file. Cover: purpose, path/query/body parameters, response shapes, and any `{{variables}}` the request depends on (with a pointer to the request that captures them). This is mandatory — the collection is the API's browsable spec.
5. Add declarative `assertions` using OpenCollection YAML's short operators (`eq`, `neq`, `lt`, `lte`, `gt`, `gte`, `contains`, `isDefined`, `isNotEmpty`). **Never write `equals`, `lessThan`, etc.** — those silently fall back to string comparison and every assertion fails at runtime.
6. Always pair an `isDefined`/`isNotEmpty` body-shape assertion with a status `eq` assertion on the same request. A 4xx body can match a `isDefined` check on the wrong key path and slip through otherwise.
7. Add a `tests` script only for checks that declarative assertions can't express (body shape, business logic, multi-value status). **Do NOT write `test("should return 200")` alongside a status assertion** — it's redundant.
8. Use the `params:` block for any query parameters. Never put them in the URL string.
9. Tag it — at minimum the domain tag. Use `smoke` only when the request's happy-path data actually exists in CI; if it's a list endpoint whose creator is `destructive`-tagged (therefore excluded from CI), use `contract` instead — "returned 200 on an empty list" is a liveness signal, not a smoke signal. Add `error-case` for validation tests, `destructive` / `manual` / `teardown` / `auth-chain` as appropriate (see Tag reference above).
10. If the request depends on an upstream-captured variable (e.g. `{{createdProjectId}}`), add a `before-request` script that throws when the variable is missing. Cite the **actual file path** of the producer in the error message (e.g. `run 10-reference-data/get-cities.yml first`), not a placeholder.
11. Never hardcode seeded IDs (`city_id: 1`, etc.). Capture them from an earlier reference-data GET via `bru.setVar` — and on that capturing GET, add a declarative `isNotEmpty` assertion on the source collection so an empty seed fails at the producer, not at the consumer.
12. Never hardcode unique-constraint values (email, username, SIRET, UUID, idempotency key). Use a `before-request` script: `bru.setVar("testEmail", bru.interpolate("{{$randomEmail}}"))`, then reference `{{testEmail}}` in the body. Hardcoded values 422 on re-run and pollute shared DBs.
13. Do NOT set `auth: inherit`, `auth: none`, or a typed `auth: { type: bearer, ... }` block anywhere. The `auth:` block is a no-op in Bruno CLI 3.2.x — auth is carried by the folder-level `Authorization` header set in `folder.yml`. To bypass auth for one request inside an authenticated folder, strip the header in a `before-request` script: `req.deleteHeader("Authorization")`.
14. For DELETE endpoints, add a follow-up `get-{resource}-after-delete.yml` that asserts 404. This is what proves the delete actually took effect.
15. Teardown requests (logout, delete test data) go in `90-cleanup/`, never inside a domain folder.
16. Run `bru run {folder} --env Development` locally to verify.
17. Commit. The pre-commit hook validates YAML syntax; CI runs the full suite on PRs.

## Environments and secrets

- Secrets (tokens, API keys, passwords) use `transient: true` in environment files — Bruno does not persist them to disk.
- Populate secrets at runtime via `--env-var KEY=value` or the Bruno GUI's runtime-variable panel.
- CI injects secrets via `<CI platform>` secrets (see `<ci workflow file>`).

## CI

The full suite runs on every PR and every push to `main` via `<ci workflow file>`. Reports are uploaded as build artifacts:

- HTML report — useful for human debugging.
- JUnit XML — consumed by the CI UI for inline pass/fail rendering.

Artifact retention is platform-specific (e.g. GitHub Actions extends `main` HTML reports to 90 days, PR reports to 14 days; GitLab and CircleCI use a uniform window). Check `<ci workflow file>` for the exact retention values.

## Troubleshooting

- **Variable shows as empty string in a request.** The variable is not declared in the active environment's YAML. Bruno does NOT error on missing vars — it substitutes empty. Add the variable to every environment file that should support the request.
- **Test passes locally but fails in CI.** Check that the variable exists in the `CI` environment file and that the corresponding secret is configured in `<CI platform>`.
- **Auth token not picked up by dependent requests.** Verify the auth request's `after-response` script calls `bru.setVar("<tokenVar>", ...)` and that dependent requests reference the same variable name in `{{...}}` interpolation.
- **`00-auth/me.yml` returns 401.** The folder-level `Authorization` header cascade is broken somewhere. Check the `folder.yml` of every authenticated folder — the `request.headers` block must carry `Authorization: Bearer {{authToken}}`. The typed `auth:` block does NOT work in Bruno CLI 3.2.x.
- **429 Too Many Requests mid-suite.** The target backend is applying a rate limit (typically Laravel's `throttle:api` at 60/min, or similar middleware elsewhere). Either raise the limit in the CI-facing backend, run the suite against a host with throttling disabled, or pass `--delay 1000` to `bru run` to space requests out. A 429 inside `10-reference-data/` is especially disruptive because it breaks the capture chain.
- **Pre-commit hook rejects a valid-looking file.** The hook parses YAML; check indentation, quoted strings, and multi-line block scalars (`|-`).

## Reference

- OpenCollection YAML format: <https://spec.opencollection.com/>
- Bruno CLI flags: `bru run --help`
- Project `CLAUDE.md` — "Bruno API Collection Maintenance" section (constraints Claude follows when editing the collection)
```
