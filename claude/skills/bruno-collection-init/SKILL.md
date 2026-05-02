---
name: bruno-collection-init
description: Generate a complete Bruno API collection at /bruno/ using the OpenCollection YAML format — environment files, request files with declarative assertions and Chai tests, a pre-commit YAML validator, and a CI workflow. Generates a path-scoped Bruno authoring rule at .claude/rules/bruno.md plus a short pointer in CLAUDE.md so subsequent edits stay consistent. Use when bootstrapping API testing for a project that does not yet have a Bruno collection.
context: fork
model: opus
effort: xhigh
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
disable-model-invocation: true
---

# Bruno Collection Generator (OpenCollection YAML)

Generate complete, production-grade Bruno API collections using the OpenCollection YAML specification (Bruno 3.0.0+).

## Scope

**This skill does:**
- Scaffold a full Bruno collection directory at `/bruno` in the project root
- Generate `opencollection.yml`, environment files, folder configs, and request `.yml` files
- Author test scripts (Chai-based) and declarative assertions for every request
- Configure authentication at collection/folder level
- Generate a human-maintainer `/bruno/README.md` and add a pointer from the project root `README.md`
- Generate a path-scoped Bruno authoring rule at `.claude/rules/bruno.md` and append a short pointer to the project's `CLAUDE.md`
- Install a pre-commit hook that validates Bruno YAML syntax
- Install a CI workflow that runs the full suite and uploads reports as artifacts

**This skill does NOT:**
- Update or maintain an existing collection (handled by the `.claude/rules/bruno.md` authoring rule, which auto-loads on edits to `bruno/**` and the project's API source paths)
- Migrate from Postman collections
- Generate GraphQL, gRPC, or WebSocket requests (HTTP only for now)
- Create a `CLAUDE.md` or project `README.md` if one doesn't already exist — flags to the user instead

## Pre-flight Check

Before generating anything, run these checks:

1. **Existing collection.** If `/bruno/opencollection.yml` exists → STOP.
   Tell the user: "A Bruno collection already exists at `/bruno/`. This skill only generates new collections. Collection maintenance and updates should happen during regular sessions — check `CLAUDE.md` (or `.claude/rules/bruno*.md`) for the maintenance rule."
   Do NOT proceed.
2. **Existing maintenance rule.** Check whether `.claude/rules/bruno*.md` already exists. If it does, the project already has a Bruno authoring rule — DO NOT overwrite it in Step 5. Skip the rule-file creation, leave the existing file untouched, and flag this in the Summary so the user can reconcile any new guidance manually.
3. **CLAUDE.md presence.** If no `CLAUDE.md` exists at the project root, DO NOT create one. Skip the CLAUDE.md pointer in Step 5 (the `.claude/rules/bruno.md` rule file is still created). Flag in the Summary that the pointer was not added and recommend running `/init` first.
4. **Existing Bruno mention in CLAUDE.md.** If `CLAUDE.md` already contains a `## Bruno` heading or any other reference to a Bruno collection, DO NOT append a duplicate pointer. Flag in the Summary so the user can verify the existing pointer references `.claude/rules/bruno.md`.
5. **Root README presence.** If no `README.md` exists at the project root, DO NOT create one. Flag in the Summary that the pointer to `/bruno/README.md` was not added.

## Workflow

### Step 1: Analyze the codebase

Read the project's backend source to extract:
- **Base URL patterns** and port configuration
- **Route/endpoint definitions** (controller files, route files, decorators, annotations)
- **HTTP methods** per endpoint
- **Request/response shapes** (DTOs, schemas, types, validation rules)
- **Authentication mechanism** (JWT, API key, OAuth2, session-based, etc.)
- **Middleware** that affects requests (rate limiting, CORS, tenant headers, etc.)
- **Environment-specific configuration** (dev/staging/prod URLs, API keys)

Group endpoints by domain (e.g., `auth`, `users`, `orders`, `admin`).

### Step 2: Read the format references

Before writing any files, read the relevant reference docs:

- **Always read now:** `references/opencollection-yaml.md` — the YAML format specification
- **Always read now:** `references/test-patterns.md` — test script and assertion patterns
- **Read if auth is non-trivial:** `references/scripting-api.md` — the full `req`, `res`, `bru` API
- **Read in Step 6:** `references/readme-template.md` — `/bruno/README.md` scaffold
- **Read in Step 8:** `references/hook-templates.md` — pre-commit hook install patterns
- **Read in Step 9:** `references/ci-templates.md` — CI workflow templates

### Step 3: Generate the collection

Follow this exact directory structure:

```
/bruno/
├── opencollection.yml           # Collection root (docs: block mandatory)
├── environments/
│   ├── development.yml
│   ├── staging.yml
│   ├── production.yml
│   └── CI.yml                   # CI environment — values overridden via --env-var
├── 00-auth/                     # Login, refresh-token, register (destructive)
│   ├── folder.yml
│   ├── login.yml                # seq 1 — captures authToken
│   ├── me.yml                   # seq 2 — auth smoke test (see Step 4)
│   └── ...
├── 10-reference-data/           # Seed variables for downstream creates
│   ├── folder.yml
│   └── get-cities.yml           # captures firstCityId, etc.
├── 20-{domain}/                 # Feature domain (no captured deps)
│   ├── folder.yml
│   ├── {operation}.yml
│   └── ...
├── 30-{domain}/                 # Feature domain that depends on 20-{domain}
│   └── ...
└── 90-cleanup/                  # Teardown (logout, delete test data)
    ├── folder.yml
    └── logout.yml               # tags: [teardown]
```

#### Naming conventions

- **Folders use numeric prefixes.** Bruno's CLI runs folders in lexicographic order, so ordering invariants (captures must run before consumers, teardown must run last) need to be encoded in the folder names themselves — not inferred from domain spelling. The scheme:
  - `00-auth/` — authentication flow (login + smoke test). Always first; captures `authToken`.
  - `10-reference-data/` (or `10-setup/`) — read-only GETs whose job is to capture reference IDs (`firstCityId`, `firstBuildingTypeId`, …) used by downstream creates.
  - `20-{domain}/`, `30-{domain}/`, …, `80-{domain}/` — feature domains. Prefix is chosen so producers sort before consumers. If domain A captures a variable that domain B needs, A gets the lower prefix. When two domains have no capture dependency, assign prefixes in alphabetical order for predictability.
  - `90-cleanup/` — teardown (logout, delete test data). Always last.
- **Folder names after the prefix** are lowercase kebab-case matching the API domain (`20-companies`, `30-company-users`).
- **Request files:** `{verb}-{resource}.yml` — e.g., `get-users.yml`, `create-order.yml`, `delete-user-by-id.yml`.
- **Environment files:** `{environment-name}.yml` — e.g., `development.yml`, `staging.yml`, `CI.yml`.
- **Sequence (`seq`):**
  - Reserve `seq` 1–9 for happy-path requests within each folder (login → CRUD: create → read → update → delete).
  - Use `seq` 10+ for error-case requests (validation, unauthorized, not-found) within the same folder.
  - The gap makes happy-path vs. error-case visually obvious in the Bruno GUI and leaves room to insert new happy-path requests without renumbering errors.

**Dependency-ordering invariant (enforced during generation):** after deciding the folder layout, verify that every folder which consumes a `bru.getVar` variable has a higher numeric prefix than the folder whose `after-response` script sets that variable. If a mismatch exists, renumber the producer down (or the consumer up) — do NOT patch around it with `setNextRequest` hacks. After generation, run `ls /bruno/` and confirm the order output matches the dependency graph. Include the final folder order in the collection-level `docs:` block so maintainers have a canonical reference.

**Every folder has a unique numeric prefix.** Two folders sharing `20-` (e.g. `20-companies` + `20-users`) fall back to alphabetical tiebreak. That's fine until someone later adds a capture in the second folder that the first consumes — at which point the tiebreak silently reverses the intent. Hard rule: one folder per prefix.

**Insertion strategy is regenerate, not renumber.** When a new feature folder needs to slot between existing ones, the maintenance rule (documented in CLAUDE.md) is to renumber the tree atomically rather than picking an awkward value (`15-` between `10-` and `20-`, then `13-`, `17-` on subsequent inserts — the space degrades fast). The skill regenerates collections atomically; for incremental hand-edits Claude renumbers uniformly when asked to add a new folder, updating any guard-script path references in the same pass.

#### Collection root (`opencollection.yml`)

```yaml
opencollection: "1.0.0"

info:
  name: "{Project Name} API Collection"
  summary: "API collection for {brief project description}"
  version: "1.0.0"

docs: |-
  # {Project Name} API

  {One-paragraph description of what the API does.}

  ## Authentication

  {How the API authenticates — e.g. OAuth2 password grant via `POST /api/auth/login`. The auth token is captured in `after-response` and injected into every dependent request as `{{authToken}}`.}

  ## Environments

  - `Development` — local dev API (`http://localhost:{port}`).
  - `Staging`, `Production` — remote instances.
  - `CI` — values injected via `--env-var` from CI secrets.

  ## Required runtime variables

  - `baseUrl`, `authToken`, and any project-specific variables referenced by the collection.

  ## Tag reference

  See `/bruno/README.md` → "Tag reference" for the full table.

config:
  environments: []  # Environments are stored as separate files

request:
  headers:
    - name: Content-Type
      value: application/json
    - name: Accept
      value: application/json
  settings:
    encodeUrl: true
    timeout: 30000
    followRedirects: true
    maxRedirects: 5
```

If the entire API uses one auth mechanism, set it at collection level via `request.auth`. Otherwise set it per folder in `folder.yml`.

The collection-level `docs:` block above is mandatory — it's the first thing the Bruno GUI shows when someone opens the collection.

#### Environment files

Each environment file defines the variables for that context. Use `{{variableName}}` interpolation in requests. YAML comments use `#`.

```yaml
name: Development
color: "#22c55e"
description: Local development environment
variables:
  # Replace 3000 with the actual port detected from the project
  # (package.json scripts, .env, server config, etc.).
  - name: baseUrl
    value: "http://localhost:3000"
  - name: apiVersion
    value: "v1"
  # Auth variables — use transient: true for secrets so they are
  # not written to disk.
  - name: authToken
    value: ""
    transient: true
```

The `CI` environment is a placeholder shell — values come from CI secrets via `--env-var` flags (see Step 9):

```yaml
name: CI
color: "#6b7280"
description: CI environment — values injected via --env-var from CI secrets
variables:
  - name: baseUrl
    value: ""           # Overridden by --env-var BASE_URL=...
  - name: apiVersion
    value: "v1"
  - name: authToken
    value: ""
    transient: true     # Overridden by --env-var BASE_URL=... at runtime
```

**Rules for environment variables:**
- `baseUrl` is always defined (every request URL starts with `{{baseUrl}}`).
- Secrets (tokens, API keys, passwords) use `transient: true` — they are not persisted to disk.
- Include all variables that differ between environments (URLs, feature flags, tenant IDs).
- The `CI.yml` file declares every variable used by the collection with empty-string values — CI overrides them at runtime via `--env-var`.
- For production placeholders, use an empty `value: ""` plus a `#` comment explaining what should be injected at runtime. Never commit a fake-looking value.

#### Folder configuration (`folder.yml`)

```yaml
info:
  name: "{Domain Name}"
  description: "{What this group of endpoints does}"

docs: |-
  # {Domain Name}

  {One-paragraph description of this domain: what business capability it represents, how its resources relate, and any domain-specific invariants callers should know about.}

  ## Conventions

  - {Domain-specific header, e.g. `X-Tenant-Id: {{tenantId}}` required.}
  - {Any domain-specific error shapes.}

request:
  # Authentication is set via a manual Authorization header, NOT via the
  # typed `auth:` block. The OpenCollection `auth: { type: bearer, token }`
  # block is a no-op in @usebruno/cli 3.2.x — it logs a silent stderr warning
  # and sends no Authorization header. Manual headers cascade correctly from
  # folder → request, so set the header here and every request inherits.
  # Drop this block on folders whose requests are all unauthenticated
  # (e.g. `00-auth/` which hosts login/register).
  headers:
    - name: Authorization
      value: "Bearer {{authToken}}"
  assertions:
    - expression: res.responseTime
      operator: lt
      value: "3000"
      description: "Folder default: respond within 3s"
```

Every authenticated folder gets the `Authorization` header block above. Folders whose requests are all unauthenticated (login, register, public reference endpoints) omit the `headers:` entry AND carry an explicit one-line YAML comment inside `request:` making the intent visible at the point of use:

```yaml
request:
  # No Authorization header — endpoints in this folder are public.
  assertions:
    - expression: res.responseTime
      operator: lt
      value: "3000"
```

Without the comment, a Bruno GUI user inspecting the folder may wonder whether the missing header is an oversight and add one.

The folder-level `docs:` block is mandatory on every folder. The response-time assertion at folder level is mandatory too — do NOT copy response-time assertions into individual request files.

#### Request files

Every request file follows this structure:

```yaml
info:
  name: "{Human-readable name}"
  type: http
  seq: {number}
  tags:
    - {domain}
    - {category}  # e.g., smoke, crud, admin

docs: |-
  # {Human-readable name}

  {One-paragraph description of what this endpoint does and when to call it.}

  ## Path / Query / Body

  - Path params: `{path_param}` — {description}
  - Query params: `{query_param}` — {description}
  - Body: `{field}` — {description, constraints}

  ## Responses

  - `{expected_status}` — {success meaning, key body fields}
  - `4xx` — {common error shapes and their meaning}

  ### Example response

  ```json
  {
    "id": 1,
    "name": "Example"
  }
  ```

  ## Depends on

  - `{{captured_variable}}` set by `{other-request}.yml` (or "none").

http:
  method: {GET|POST|PUT|PATCH|DELETE}
  url: "{{baseUrl}}/api/{path}"
  headers:
    - name: "{Header-Name}"
      value: "{value}"
  params:
    - name: "{param}"
      value: "{value}"
      type: query  # or path
  body:  # Only for POST/PUT/PATCH
    type: json
    data: |-
      {
        "field": "value"
      }

runtime:
  assertions:
    - expression: res.status
      operator: eq
      value: "{expected_status}"
      description: "Should return {expected_status}"
    - expression: res.headers['content-type']
      operator: contains
      value: "application/json"
  scripts:
    - type: tests
      code: |-
        # Body-shape / business-logic checks only.
        # Status, content-type, response time → declarative assertions above.
        test("should return valid response body", function() {
          const body = res.getBody();
          expect(body).to.have.property("{key}");
        });

settings:
  encodeUrl: true
```

Do NOT add an `auth:` block (`auth: inherit`, `auth: none`, or a typed bearer block) on request files. The typed auth block is a no-op in Bruno CLI 3.2.x, so it either does nothing (inherit / none) or silently fails to send the header. Auth is carried exclusively by the folder-level `headers:` entry set in `folder.yml`. Requests inside an authenticated folder inherit the header automatically; requests inside an unauthenticated folder (e.g. `00-auth/`) get no header because the folder doesn't set one. If a single request inside an otherwise-authenticated folder needs to bypass auth, strip the header with a `before-request` script: `req.deleteHeader("Authorization")`.

**Operator names:** OpenCollection YAML uses short names (`eq`, `neq`, `lt`, `lte`, `gt`, `gte`, `contains`, `isDefined`, `isNotEmpty`, …). Writing `equals`, `lessThan`, `notEquals` etc. looks correct but silently falls back to string comparison and every assertion will fail at runtime. See `references/opencollection-yaml.md` for the full list.

**`isDefined` alone is insufficient.** Bruno's `isDefined` operator is permissive — on a 401 where `res.body = { message: "Unauthenticated." }`, an assertion `res.body.data.id: isDefined` passes. Always pair `isDefined` (or `isNotEmpty`) on a body field with a status `eq` assertion on the same request, so a 4xx can never slip through.

**Query parameters — always use the `params:` block.** Never put query strings directly in `url:`. The `params:` block is what the Bruno GUI writes when you edit query params, it parametrizes cleanly (`value: "{{searchTerm}}"`), and it keeps query state visible to the runner. If you're tempted to append `?foo=bar` to a URL, lift it into `params:` with `type: query`.

**Per-request `docs:` block is mandatory.** Every request file ships with a `docs:` markdown block covering purpose, path/query/body parameters, response shapes, and any upstream variables it depends on. This is the endpoint's in-collection spec — skipping it on "trivial" reference-data GETs is not allowed. Copy the template structure above and fill in every section; if a section is empty (no path params, no dependencies), write "none" — don't delete the heading.

**`docs:` blocks must NOT wrap lines.** Write each sentence or paragraph on a single continuous line — never insert a line break to satisfy an 80- or 120-character column limit. Hard line breaks inside a `docs:` block render as line breaks in Bruno's GUI Docs tab and break mid-sentence in the YAML source view. This rule applies to `opencollection.yml`, every `folder.yml`, and every request file.

### Step 4: Author test scripts

Read `references/test-patterns.md` for the full pattern catalog before writing tests. Key rules below.

**Division of labor — assertions vs. tests:**

- **`runtime.assertions`** covers the uniform per-request checks: status, content-type, response time. Declarative, first-class in JUnit output.
- **`runtime.scripts` → `type: tests`** is reserved for things declarative assertions can't express: body shape, business-logic invariants, multi-value status (e.g. DELETE → 200 or 204).

**Do NOT write `test("should return 200", …)` blocks** when a status assertion already covers it — that's duplicated effort and drifts out of sync. This is the single biggest source of report noise.

**Response-time SLA: always at folder level.** The folder-level `request.assertions:` in `folder.yml` carries the response-time bound. Every request inherits. Override at request level only when the specific endpoint has a documented reason for a different bound.

**Minimum per-request checks:**

1. `docs:` block (see request template above).
2. Status code assertion (`eq`, `neq`, or `gte`/`lt` for ranges).
3. Content-type assertion (`contains "application/json"`).
4. Response time — inherited from folder; do NOT copy into the request.
5. At least one body/business-logic test in a `tests` script.

**For auth endpoints**, additionally:
- Capture tokens/session data with `bru.setVar()` in an `after-response` script.
- Dependent requests reference the captured variable via `{{varName}}`.

**For CRUD endpoints**, additionally:
- Create → capture the created resource ID in an `after-response` script.
- Read/Update/Delete → guard with a `before-request` script that throws if the captured ID is missing (see `references/test-patterns.md` → "Guard chained requests against empty variables"). Without this guard, a missing `createdProjectId` interpolates to an empty string and the URL becomes `/api/projects/` — which silently hits a different route and masks the failure.
- Delete → add a follow-up request that reads the deleted resource and asserts 404. This proves the delete actually happened and wasn't a silent no-op.

**For error cases**, add tagged requests:
- `{operation}-invalid.yml` with tag `error-case` to test validation/400 responses.
- `{operation}-unauthorized.yml` with tag `error-case` to test 401/403 responses.

**Never hardcode seeded IDs** (`city_id: 1`, `company_id: 1`, `building_type_id: 1`, …). A fresh DB will 404 on every one of them. Always capture IDs in an `after-response` script on an early reference-data GET:

```javascript
bru.setVar("firstCityId", res.getBody().data[0].id);
```

Dependent requests then reference `{{firstCityId}}`. Document which reference-data GETs are seeding which variables in `/bruno/README.md`.

**Destructive endpoints.** Endpoints that seed real data, send emails, call third-party services, or otherwise break on re-run (registration, webhook triggers, etc.) MUST be tagged `destructive`. CI excludes them via `--exclude-tags=destructive`. Endpoints that require out-of-band input (emailed tokens, 2FA codes, manual confirmation) MUST be tagged `manual` and excluded the same way. See `references/test-patterns.md` → "Tag conventions".

**Dynamic test data — never hardcode unique-constraint values.** Any request that creates or submits entities with server-side uniqueness constraints (emails, usernames, SIRETs, tenant slugs, external IDs, idempotency keys, UUIDs) MUST pull unique values from Bruno's dynamic variables, not from hardcoded strings. A hardcoded `jean.dupont+bruno@example.com` works the first time, 422s on every subsequent run, and pollutes shared databases with duplicate rows.

The canonical pattern: a `before-request` script calls `bru.interpolate()` on the built-in `$random*` variables and stores the result in a run-scoped variable, which the body then references.

```yaml
scripts:
  - type: before-request
    code: |-
      bru.setVar("testEmail", bru.interpolate("{{$randomEmail}}"));
      bru.setVar("testFirstName", bru.interpolate("{{$randomFirstName}}"));
      bru.setVar("testSiret", String(Math.floor(1e13 + Math.random() * 9e13)));
http:
  body:
    type: json
    data: |-
      {
        "email": "{{testEmail}}",
        "firstName": "{{testFirstName}}",
        "siret": "{{testSiret}}"
      }
```

Use this pattern on every `destructive`-tagged create request, and on any non-destructive request whose payload hits a uniqueness constraint. Bruno's `{{$random*}}` family (`$randomEmail`, `$randomFirstName`, `$randomLastName`, `$randomFullName`, `$randomUUID`, `$randomInt`, `$timestamp`, …) is documented in `references/scripting-api.md` — prefer these over ad-hoc `Date.now()` strings wherever an equivalent exists, since they produce realistic-looking data.

**Auth is set by a folder-level `Authorization` header, not by the `auth:` block.** The OpenCollection YAML `auth: { type: bearer, token }` block is a no-op in `@usebruno/cli` 3.2.x — the CLI's internal `toBrunoAuth` switch keys off a different field shape, silently falls through to a "unsupported auth type" stderr warning, and sends no `Authorization` header. Until the upstream bug (`usebruno/bruno` #2326, #3688) is fixed, every authenticated folder's `folder.yml` carries a manual `headers:` entry:

```yaml
request:
  headers:
    - name: Authorization
      value: "Bearer {{authToken}}"
```

Folder-level `headers:` cascade correctly into request files (only the `auth:` block is broken). Unauthenticated folders (`00-auth/`, public reference endpoints) simply omit the header. The `--reporter-skip-headers "Authorization"` flag already scrubs the value from CI artifacts, so the usual argument against manual headers doesn't apply.

**Auth smoke test is mandatory.** `00-auth/me.yml` (or a project-appropriate equivalent that calls an authenticated "current user" endpoint) is required. Its job is to assert that the `Authorization` header actually survived the request — a 200 here means the folder-header inheritance is intact and every downstream folder can rely on it. If this smoke request fails, every subsequent authenticated folder fails deterministically, so we catch the regression in one assertion instead of dozens. Place it at `seq: 2` (after `login.yml`).

**Capture-producer endpoints hard-assert the response is non-empty.** A GET whose `after-response` script sets a downstream variable (`bru.setVar("firstCityId", body.data[0].id)`) MUST include a declarative assertion that the source collection is non-empty. Without it, an empty-list response (valid on a fresh DB, but semantically broken for capture purposes) returns 200, the capture silently no-ops, and the *consumer* request throws — pointing blame at the wrong file. Turn this into a single, correctly-attributed failure at the producer:

```yaml
# reference-data/get-cities.yml
runtime:
  assertions:
    - expression: res.status
      operator: eq
      value: "200"
    - expression: res.body.data
      operator: isNotEmpty
      description: "Captures firstCityId — must return at least one row"
```

**Guard scripts reference the actual producer path.** When writing a `before-request` guard that throws on a missing captured variable, the error message must cite the exact path of the file that captures it (e.g. `throw new Error("firstCityId missing — run 10-reference-data/get-cities.yml first")`). Do not use placeholder paths copied from a template — a wrong path in the guard message wastes the maintainer's time when the guard actually fires. After generation, cross-check every guard's referenced path against the actual file layout.

**Teardown lives in `90-cleanup/`.** The Bruno CLI runs folders in lexicographic order, so teardown requests (logout, delete test data) MUST live in the numerically-last folder, `90-cleanup/`, and be tagged `teardown`. CI excludes `teardown` from the default run; maintainers run it explicitly. Never put logout inside `00-auth/` or any domain folder — the `after-response` script that revokes the token would cascade into 401s across every downstream folder.

**Tag multi-step auth flows with `auth-chain`.** A `refresh-token.yml` request that fires on every run exercises the refresh grant (and its token-rotation side effect) on every single CI invocation — which is more than "verify login works" needs. Tag `refresh-token.yml` with `auth-chain` so it runs only when a maintainer explicitly asks for it (`bru run 00-auth --tags=auth-chain`). The default suite just verifies the plain login → authenticated-request path.

**`smoke` vs `contract`.** Tag a request `smoke` only when its happy-path actually exercises real data in CI. A list endpoint whose sole creator is `destructive`-tagged (and therefore excluded from CI) returns an empty collection on every CI run — the assertion "returned 200" is a tautology, not a smoke test. For that class of request, use the `contract` tag instead:

- `smoke` — critical-path request whose happy-path data exists in CI. Failure means a real regression.
- `contract` — liveness / route-exists check. Passes on an empty DB. Useful for "the endpoint is still registered" but not a smoke signal.

The distinction shows up in CI reports: a drop in `smoke` pass rate is an action signal; a drop in `contract` is a deployment signal. Use `--tags=smoke` for fast PR checks; include `contract` for full-suite runs.

**Mirrored requests carry a regeneration marker.** When the collection duplicates a request across folders for isolation-run support (e.g. `00-auth/me.yml` as the Authorization canary, plus `20-users/get-me.yml` so `20-users/` is runnable standalone), both copies MUST open with a YAML comment flagging the duplication:

```yaml
# Mirrors 00-auth/me.yml — keep both in sync when the endpoint evolves.
info:
  name: Get Me
  ...
```

Without the marker, drift between the two files is a matter of time.

**Every `req.deleteHeader("Authorization")` call has an explanatory comment.** The pattern is a convention (because `auth: none` is a no-op in Bruno CLI 3.2.x), not a language primitive — future editors can silently undo it by adding an explicit `Authorization` header block. The comment directly above the call states the intent:

```yaml
scripts:
  # Strip the inherited Authorization header — this request must reach
  # the unauthenticated branch. `auth: none` would be a no-op in Bruno CLI 3.2.x.
  - type: before-request
    code: |-
      req.deleteHeader("Authorization");
```

**Sandbox mode:** Bruno 3.0+ runs scripts in Safe Mode by default (no `require()`, no `fs`). If any generated test legitimately needs Node APIs (e.g. signing JWTs in a `before-request` script), document it in `/bruno/README.md` and add `--sandbox=developer` to the relevant `bru run` invocations. Default to Safe Mode whenever possible.

**`docs:` blocks everywhere.** OpenCollection YAML supports a top-level `docs:` markdown key on `opencollection.yml`, `folder.yml`, and every request file. The skill writes all three — collection-level, per-folder, and per-request. Bruno GUI renders these in the "Docs" tab, which makes the collection browsable as API documentation. This is not optional: every file generated by this skill ships with a filled-in `docs:` block. See the templates above for the required structure.

### Step 5: Generate the Bruno authoring rule and CLAUDE.md pointer

The maintenance guidance has two parts:

1. **`.claude/rules/bruno.md`** — the full DO/DO NOT authoring ruleset, scoped via `paths:` frontmatter so it loads only when Claude reads files matching `bruno/**` or the project's API source directories. This is the canonical home for the rules: keeping them out of `CLAUDE.md` avoids burning unconditional context tokens on guidance that only matters when API/Bruno files are in play.
2. **CLAUDE.md pointer** — a short trigger section telling Claude when to update Bruno (the *when*), referencing the rule file for the *how*. Added only if `CLAUDE.md` exists and does not already mention Bruno.

Skip the rule-file creation if `.claude/rules/bruno*.md` already exists (pre-flight #2 — leave the existing file untouched, flag in Summary). Skip the pointer if no `CLAUDE.md` (pre-flight #3) or if `CLAUDE.md` already mentions Bruno (pre-flight #4) — both flagged in Summary.

#### Compute activation paths

From the codebase analysis (Step 1), pick the directories and files that define the API surface — these are the paths whose edits should activate the rule. Always include:

- `bruno/**` — so edits inside the collection itself activate the rule.
- The HTTP route definition file(s) (e.g. `routes/api.php` for Laravel, `src/routes/**` for Express, `app/api/**/route.ts` for Next.js, `internal/router/**` for Go).
- The controller / handler directory (e.g. `app/Http/Controllers/Api/**`, `src/controllers/**`, `internal/handlers/**`).
- The request-validation layer if separate from controllers (e.g. `app/Http/Requests/Api/**`, `src/dto/**`, `internal/schemas/**`).

Use the same path list verbatim in the rule file frontmatter and the CLAUDE.md pointer (the pointer omits the `bruno/**` entry — its purpose is to remind Claude to *go touch* Bruno when working elsewhere). If the project's structure is non-obvious, flag the chosen paths in the Summary so the user can adjust.

#### Create `.claude/rules/bruno.md`

Create the `.claude/rules/` directory if it does not exist. Write the rule file with this structure (the path list is project-specific; the body is the canonical ruleset):

````markdown
---
paths:
  - 'bruno/**'
  - '<api-route-file-or-glob>'
  - '<controller-glob>'
  - '<request-validation-glob>'
---

# Bruno API Collection Authoring

The Bruno collection at `/bruno/` is the CI contract for the API. Format is OpenCollection YAML (`.yml`). Human-maintainer docs: `/bruno/README.md`. A pre-commit hook validates YAML syntax; CI runs the full suite on PRs.

**DO:**
- Use OpenCollection YAML's **short** operator names in `runtime.assertions`: `eq`, `neq`, `lt`, `lte`, `gt`, `gte`, `contains`, `isDefined`, `isNotEmpty`. Writing `equals`, `lessThan`, `notEquals` (the Bru-lang / Chai names) silently falls back to string comparison — every assertion will then fail at runtime against a literal like `"equals 200"`.
- Put uniform checks (status, content-type) in `runtime.assertions` and reserve `runtime.scripts` → `type: tests` for body shape and business logic. Do NOT add a `test("should return 200")` that duplicates the status assertion.
- Keep the response-time SLA in `folder.yml` under `request.assertions:`. Do NOT copy response-time assertions into individual request files.
- Write script tests with Chai's `expect` syntax (e.g. `expect(res.getBody()).to.have.property("id")`). Bruno's runner does not support Jest/Vitest syntax — wrong syntax fails silently at runtime, not at parse.
- Name request files `{verb}-{resource}.yml` (e.g. `get-users.yml`). Combined with `seq`, each folder reads as a logical CRUD flow.
- Add a `docs:` markdown block on `opencollection.yml`, every `folder.yml`, and every request file. Bruno GUI renders them in the Docs tab — the collection doubles as browsable API documentation.
- Always use the `params:` block for query parameters. Never append `?foo=bar` to a URL.
- Keep environment files in sync when adding a variable. Bruno does NOT error on missing variables — it substitutes empty string silently, so a var present in `development.yml` but absent from `CI.yml` masks the bug in CI.
- Capture auth tokens in an `after-response` script via `bru.setVar("authToken", ...)`; dependent requests consume `{{authToken}}`. Moving capture into a `tests` block or hardcoding tokens breaks the chain.
- Capture reference-data IDs the same way. The first GET on a reference-data endpoint sets `firstCityId`, `firstCompanyId`, etc. — downstream creates consume them via `{{firstCityId}}`. Never hardcode numeric/UUID IDs.
- For request bodies with server-side uniqueness constraints (email, username, SIRET, tenant slug, external ID, idempotency key), pull unique values from Bruno's dynamic variables in a `before-request` script: `bru.setVar("testEmail", bru.interpolate("{{$randomEmail}}"))`, then reference `{{testEmail}}` in the body. Hardcoded values 422 on every re-run and pollute shared DBs. See `/bruno/README.md` for the built-in `{{$random*}}` list.
- Set authentication via a folder-level `headers: [{ name: Authorization, value: "Bearer {{authToken}}" }]` entry in `folder.yml`. The typed `auth: { type: bearer, token }` block is a no-op in `@usebruno/cli` 3.2.x — it logs a silent stderr warning and sends no `Authorization` header. Manual folder-level headers cascade correctly into requests. CI scrubs the value via `--reporter-skip-headers "Authorization"`.
- Keep `00-auth/me.yml` (or equivalent authenticated smoke request) in the default suite. If the `Authorization` header cascade ever breaks again, this single request fails first — ahead of the dozens of feature-folder requests that would otherwise cascade-fail for the same root cause.
- Name folders with numeric prefixes (`00-auth/`, `10-reference-data/`, `20-…/`, …, `90-cleanup/`) so lexicographic execution order matches dependency order. If folder X captures a variable that folder Y consumes, X's prefix must be numerically smaller.
- Capture-producer GETs (reference-data endpoints whose `after-response` script sets a `firstX` variable) include an `isNotEmpty` assertion on the captured collection. An empty-list response on a fresh DB would otherwise 200 silently and push the failure into downstream consumers.
- When writing a `before-request` guard that throws on a missing captured variable, the error message cites the exact file path that captures it (e.g. `run 10-reference-data/get-cities.yml first`). Do not leave a template placeholder — update the message when you move or rename the producer.
- Always pair `isDefined`/`isNotEmpty` on a body field with a status `eq` assertion on the same request. Bruno's `isDefined` is permissive — it passes on 4xx error bodies that happen to contain a different shape.
- Keep every folder's numeric prefix unique. If two folders would tie (e.g. both `20-`), renumber one of them — alphabetical tiebreak is a latent hazard the first time a capture dependency crosses the tie.
- When a request uses `req.deleteHeader("Authorization")`, precede the call with a YAML comment naming the intent ("Strip inherited Authorization — this request must reach the unauthenticated branch"). `auth: none` is a no-op, so the only thing keeping the request unauthenticated is that delete call; make its purpose visible.
- When the collection legitimately duplicates a request across folders for isolation-run support, open both files with `# Mirrors {path} — keep both in sync when the endpoint evolves.` Drift is otherwise a matter of time.
- Use `contract` instead of `smoke` on list endpoints whose only source of data is a `destructive`-tagged create. Those list calls return an empty collection in CI (the create is excluded), so "returned 200" is a liveness signal, not a smoke signal. `smoke` is reserved for requests whose happy-path data exists in CI.
- Guard chained requests with a `before-request` script that throws when the upstream-captured variable is missing (`if (!bru.getVar("createdProjectId")) throw new Error(...)`). Without the guard, a missing ID interpolates to empty string and the request silently hits a collection-level route with misleading 404/405.
- Tag endpoints with side effects. `destructive` for non-idempotent writes that seed real data, send emails, or hit third-party services (e.g. registration). `manual` for endpoints requiring out-of-band input (emailed tokens, 2FA). `teardown` for logout / cleanup. `auth-chain` for refresh-token and similar multi-step auth flows that don't need to fire on every run. CI excludes `destructive,manual,teardown` via `--exclude-tags`.
- Put every teardown request in `90-cleanup/`. The CLI runs folders in lexicographic order; the numeric prefix guarantees cleanup runs last.

**DO NOT:**
- DO NOT generate `.bru` format files. The project standard is OpenCollection YAML (`.yml`) — mixing formats breaks tooling.
- DO NOT hardcode base URLs in requests. Always use `{{baseUrl}}` — hardcoded URLs silently bypass environment switching.
- DO NOT hardcode seeded IDs (`city_id: 1`, `company_id: 1`, `building_type_id: 1`). A fresh DB will 404 every hardcoded ID. Capture them from an earlier reference-data GET via `bru.setVar`.
- DO NOT hardcode email addresses, usernames, SIRETs, UUIDs, or any other value the server treats as unique. Use `bru.interpolate("{{$randomEmail}}")` and friends in a `before-request` script.
- DO NOT use the typed `auth: { type: bearer, token: ... }` block, or `auth: inherit`, or `auth: none`. These are no-ops in `@usebruno/cli` 3.2.x — the CLI logs a stderr warning and sends no `Authorization` header. Set authentication via a folder-level manual `headers:` entry instead.
- DO NOT commit real tokens, passwords, or API keys. Secrets use environment variables with `transient: true` so they are never persisted to disk.
- DO NOT put logout (or any `teardown`-tagged request) outside of `90-cleanup/`. The CLI runs folders in lexicographic order; a `logout` inside `00-auth/` or any domain folder revokes the token for every downstream folder.
- DO NOT put query parameters in the URL string. Always use the `params:` block with `type: query`.
- DO NOT rely on `isDefined`/`isNotEmpty` alone to signal a successful response — always pair with a status `eq` assertion on the same request.
- DO NOT add a new feature folder without checking its numeric prefix against the capture-dependency graph. Producers must have smaller prefixes than their consumers.
- DO NOT ship a request file, folder, or `opencollection.yml` without a filled-in `docs:` block.
````

The "when to update Bruno" trigger (the previous leading "When adding, modifying, or removing API endpoints…" bullet) is now carried by the CLAUDE.md pointer below — the rule file's body covers *how* to author, not *when* to update.

If the codebase analysis surfaced project-specific contracts that recur across endpoints (response envelope shape, token-payload nesting, tenant header convention, etc.), append them as additional DO bullets. They are the most valuable thing this rule file can carry — generic rules apply to every project, project-specific rules don't.

#### Append the CLAUDE.md pointer

If `CLAUDE.md` exists and does not already mention Bruno, append:

```markdown
## Bruno API Collection Maintenance

When touching `<api-route-path>`, `<controller-glob>`, or `<request-validation-glob>`, also update the matching file in `/bruno/`. Authoring rules are in `.claude/rules/bruno.md` and activate automatically.
```

The path callouts are the same paths used in the rule file frontmatter, minus `bruno/**`. Adapt the wording to read naturally for the project's stack — but keep the path callouts concrete (no "various API files"). The pointer must reference `.claude/rules/bruno.md` explicitly so a maintainer reading `CLAUDE.md` can find the full ruleset.

### Step 6: Generate `/bruno/README.md`

Using `references/readme-template.md` as the scaffold, generate `/bruno/README.md`. Fill in the project-specific placeholders:

- `<project-specific start command>` — how to start the local API server (infer from `package.json` scripts, Makefile, or project README).
- `<CI platform>` — the platform detected in Step 9 (GitHub Actions / GitLab CI / CircleCI).
- `<ci workflow file>` — the path written in Step 9 (e.g. `.github/workflows/bruno.yml`).
- `<tokenVar>` — the actual variable name used for auth capture in Step 3 (e.g. `authToken`).

If any placeholder cannot be confidently filled, leave it as `<...>` and list it in the Summary for manual completion.

### Step 7: Add pointer from the root README

If a `README.md` exists at the project root, add a short section pointing to `/bruno/README.md`. Place it under an existing "Testing", "API", "Development", or "Contributing" section if one exists; otherwise append a new top-level section above any license/footer content.

```markdown
## API collection

The project ships an executable API test collection under [`/bruno/`](./bruno/README.md), authored in Bruno's OpenCollection YAML format. See [`bruno/README.md`](./bruno/README.md) for how to run it locally, add new endpoints, and review CI output.
```

Skip if no root `README.md` exists (flagged in pre-flight).

### Step 8: Install the pre-commit YAML validation hook

Follow `references/hook-templates.md`:

1. Detect the hook framework (Husky → pre-commit framework → Lefthook → raw `.git/hooks/`).
2. Create `scripts/validate-bruno-yaml.sh` with the shared script body. `chmod +x`.
3. Wire it into the detected framework using the entry from the template.
4. Flag to the user which framework was picked and whether `yq` / `js-yaml` needs installing.

Do NOT run the hook as part of this skill — the user commits first.

### Step 9: Install the CI workflow

Follow `references/ci-templates.md`:

1. Detect the CI platform (GitHub Actions → GitLab CI → CircleCI). If none, default to GitHub Actions and flag.
2. Write the workflow file at the platform's conventional path.
3. In the Summary, list the secrets the user must configure in the platform's settings (e.g. `API_BASE_URL`, `API_KEY`).

Do NOT trigger the CI job — it runs on the next push.

### Step 10: Summary

After generation, provide the user with:
- Total number of requests generated
- List of folders/domains covered
- Environments created
- Any endpoints that couldn't be fully scaffolded (missing type info, ambiguous auth) — flag for manual completion
- Any placeholders left as `<...>` in `/bruno/README.md`
- Which hook framework was picked (or that a raw `.git/hooks/pre-commit` was used — recommend upgrading)
- Which CI platform was targeted and the list of secrets to configure
- Whether `.claude/rules/bruno.md` was created (or skipped because one already existed) and whether the CLAUDE.md pointer was added (or skipped — no `CLAUDE.md`, or `CLAUDE.md` already mentions Bruno). Include the activation paths chosen so the user can verify them.
- Any pre-flight flags: no `CLAUDE.md`, no root `README.md`, existing `.claude/rules/bruno*.md`, or existing Bruno mention in `CLAUDE.md`
- Reminder to install Bruno CLI: `npm install -g @usebruno/cli`
- Reminder to open the collection in Bruno GUI to verify

## Critical Rules

1. **NEVER generate a collection if one already exists.** Check for `/bruno/opencollection.yml` first.
2. **Use OpenCollection YAML short operators** (`eq`, `neq`, `lt`, `lte`, `gt`, `gte`, `contains`, …). Never write `equals`, `lessThan`, `notEquals` in `runtime.assertions` — those silently fall back to string comparison and every assertion fails at runtime.
3. **No duplicate status checks.** Status and content-type go in `runtime.assertions`; `tests` scripts cover body shape and business logic only. Never write `test("should return 200")` alongside a status assertion.
4. **`isDefined` / `isNotEmpty` must be paired with a status `eq` assertion.** Bruno's `isDefined` passes on 4xx bodies — standalone, it's not a positive-path signal.
5. **Response-time SLA lives at folder level.** `folder.yml` sets `res.responseTime lt 3000` (or domain-specific bound); requests inherit. Never copy response-time assertions into individual request files.
6. **Every generated file has a `docs:` block.** Collection root, every folder, every request. No exceptions.
6a. **`docs:` block content never wraps lines.** Each sentence or paragraph is a single unbroken line — no soft-wrapping at 80 or 120 characters. Hard line breaks render as forced breaks in Bruno's GUI Docs tab and break mid-sentence in the YAML source.
7. **Query parameters always go in the `params:` block.** Never in the URL string.
8. **No hardcoded seeded IDs.** Always capture from an earlier reference-data GET via `bru.setVar` and reference via `{{...}}`.
9. **No hardcoded unique-constraint values.** Emails, usernames, SIRETs, UUIDs, idempotency keys, etc. always come from `bru.interpolate("{{$randomEmail}}")` and the rest of Bruno's `{{$random*}}` family, set in a `before-request` script.
10. **Auth flows through a folder-level manual `Authorization` header.** The typed `auth:` block is a no-op in `@usebruno/cli` 3.2.x. Every authenticated folder's `folder.yml` carries `headers: [{ name: Authorization, value: "Bearer {{authToken}}" }]`. No `auth: inherit` / `auth: none` / `auth: { type: bearer }` anywhere.
11. **`00-auth/me.yml` (or project-appropriate authenticated smoke request) ships in every generated collection.** It's the single-assertion canary for the Authorization cascade — if it fails, every downstream folder fails for the same root cause.
12. **Capture-producer GETs hard-assert the captured collection is non-empty.** A GET whose `after-response` sets a downstream variable includes `isNotEmpty` on the source collection — failures surface at the producer, not the consumer.
13. **Guard scripts cite the actual producer file path.** Cross-check every `before-request` throw message against the real folder layout after generation.
14. **Folders use numeric prefixes** (`00-auth/`, `10-reference-data/`, `20-…/`, …, `90-cleanup/`). Every prefix is unique — no two folders share a number. Capture producers must have smaller prefixes than their consumers — verify with `ls /bruno/` after generation.
15. **All URLs use `{{baseUrl}}` interpolation.** Never hardcode base URLs.
16. **Secrets use `transient: true`.** Never commit real tokens or passwords.
17. **YAML only.** Do not generate `.bru` format files. The company standard is OpenCollection YAML.
18. **Tag destructive, manual, teardown, and auth-chain requests.** `destructive` for non-idempotent writes / third-party side effects; `manual` for out-of-band input requirements; `teardown` for logout and cleanup; `auth-chain` for multi-step auth flows (refresh-token) that don't need to run on every suite invocation. CI excludes `destructive,manual,teardown` by default.
19. **Every request must have at least a domain tag.** Use `smoke` for critical-path requests whose happy-path data exists in CI, `contract` for liveness-only checks on list endpoints whose creator is `destructive`-tagged (the list returns empty in CI — tagging it `smoke` would make the assertion a tautology), and `error-case` for error validation requests.
20. **Guard chained requests** with `before-request` checks that throw on missing upstream variables.
21. **Teardown always lives in `90-cleanup/`.** Never put logout or cleanup inside `00-auth/` or any domain folder.
22. **Generate `.claude/rules/bruno.md` plus a CLAUDE.md pointer.** The full DO/DO NOT ruleset lives in `.claude/rules/bruno.md` with a `paths:` frontmatter glob (always including `bruno/**` plus the project's API source paths) so it auto-loads only when relevant files are touched. Append a short pointer to `CLAUDE.md` (when one exists and does not already mention Bruno) that names the trigger paths and references the rule file by path. Skip the rule file if `.claude/rules/bruno*.md` already exists. Skip the pointer if `CLAUDE.md` is missing or already mentions Bruno. Never create a `CLAUDE.md` yourself.
23. **Generate `/bruno/README.md` for human maintainers.** Not optional.
24. **Install the pre-commit hook and CI workflow.** Detect the frameworks in use and wire the generated files in; never trigger the hook or the CI job as part of the skill run.
25. **Never create a root `README.md` or `CLAUDE.md`.** Flag in the Summary instead.
