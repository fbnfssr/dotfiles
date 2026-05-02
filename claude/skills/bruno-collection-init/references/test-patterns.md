# Bruno Test Patterns & CLI Reference

Patterns for writing test scripts, declarative assertions, and running collections via CLI.

## Table of Contents

1. [Test Script Fundamentals](#test-script-fundamentals)
2. [Assertion Patterns by Endpoint Type](#assertion-patterns-by-endpoint-type)
3. [Declarative Assertions](#declarative-assertions)
4. [Chaining Requests with Variables](#chaining-requests-with-variables)
5. [Error Case Testing](#error-case-testing)
6. [Chai Assertion Cheat Sheet](#chai-assertion-cheat-sheet)
7. [Bruno CLI Reference](#bruno-cli-reference)
8. [CI/CD Integration](#cicd-integration)

---

## Test Script Fundamentals

Bruno uses the **Chai** library (`expect` syntax) for script-based tests. Declarative `assertions` use OpenCollection YAML's short-name operators (`eq`, `neq`, `lt`, `lte`, `gt`, `gte`, `contains`, …) — see `opencollection-yaml.md`.

### Division of labor — assertions vs. tests

Every request gets both blocks, but they cover different ground:

- **`runtime.assertions`** — the default place for status code, content-type, and response-time checks. These are declarative, first-class in JUnit output, and cheap to write. Keep them uniform across every request.
- **`runtime.scripts` → `type: tests`** — reserved for checks a declarative assertion can't express: body shape, business-logic invariants, cross-field consistency, multi-value sets (e.g. DELETE returning 200 or 204).

**Do NOT write a `test("should return 200")` block that duplicates the status-code assertion** — it adds noise to JUnit reports and drifts out of sync. If the declarative assertion covers it, skip the test.

### Minimum per-request checks

```yaml
runtime:
  assertions:
    - expression: res.status
      operator: eq
      value: "200"
      description: "Status code is 200"
    - expression: res.headers['content-type']
      operator: contains
      value: "application/json"
      description: "Returns JSON"
    - expression: res.responseTime
      operator: lt
      value: "2000"
      description: "Responds within 2s"
  scripts:
    - type: tests
      code: |-
        # Body-shape / business-logic checks only.
        # Status and response-time are covered by assertions above.
        test("should return the expected resource shape", function() {
          const body = res.getBody();
          expect(body).to.have.property("id");
          expect(body).to.have.property("name");
        });
```

### Folder-level defaults

The response-time SLA is always set at the folder level in `folder.yml` under `request.assertions:`. Requests inherit. Override per-request only when a specific endpoint has a documented reason for a tighter or looser bound. Never copy the assertion into individual request files.

```yaml
# folder.yml
request:
  assertions:
    - expression: res.responseTime
      operator: lt
      value: "3000"
      description: "Default 3s SLA for this folder"
```

---

## Assertion Patterns by Endpoint Type

### GET (list) — e.g., `get-users.yml`

```yaml
runtime:
  assertions:
    - expression: res.status
      operator: eq
      value: "200"
    - expression: res.body
      operator: isArray
    - expression: res.headers['content-type']
      operator: contains
      value: "application/json"
    - expression: res.responseTime
      operator: lt
      value: "2000"
  scripts:
    - type: tests
      code: |-
        test("should return items with required fields", function() {
          const body = res.getBody();
          if (body.length > 0) {
            expect(body[0]).to.have.property("id");
          }
        });
```

### GET (single) — e.g., `get-user-by-id.yml`

```yaml
runtime:
  assertions:
    - expression: res.status
      operator: eq
      value: "200"
    - expression: res.body.id
      operator: isDefined
  scripts:
    - type: tests
      code: |-
        test("should return the requested resource", function() {
          const body = res.getBody();
          expect(body).to.have.property("id");
          expect(body).to.have.property("name");
        });
```

### POST (create) — e.g., `create-user.yml`

```yaml
runtime:
  assertions:
    - expression: res.status
      operator: eq
      value: "201"
      description: "Returns 201 Created"
    - expression: res.body.id
      operator: isDefined
      description: "Returns an ID"
  scripts:
    - type: tests
      code: |-
        test("should return the created resource with an ID", function() {
          const body = res.getBody();
          expect(body).to.have.property("id");
          expect(body.id).to.not.be.null;
        });

        test("should reflect the submitted data", function() {
          const body = res.getBody();
          expect(body).to.have.property("name");
          expect(body).to.have.property("email");
        });

    - type: after-response
      code: |-
        // Capture created ID for subsequent requests
        const body = res.getBody();
        if (body && body.id) {
          bru.setVar("createdUserId", body.id);
        }
```

### PUT/PATCH (update) — e.g., `update-user.yml`

```yaml
runtime:
  assertions:
    - expression: res.status
      operator: eq
      value: "200"
  scripts:
    - type: tests
      code: |-
        test("should return the updated resource", function() {
          const body = res.getBody();
          expect(body).to.have.property("id");
          // Verify the updated fields match what was sent
        });
```

### DELETE — e.g., `delete-user.yml`

`DELETE` returns either 200 or 204. A multi-value status can't be expressed as a single canonical-operator assertion, so use a Chai test. Always pair it with a follow-up `get-{resource}-after-delete.yml` request that asserts 404 — this is what proves the delete actually happened and wasn't a silent no-op.

```yaml
runtime:
  scripts:
    - type: tests
      code: |-
        test("should return 200 or 204", function() {
          expect(res.getStatus()).to.be.oneOf([200, 204]);
        });
```

### Auth smoke test — e.g., `00-auth/me.yml`

Every generated collection ships with an authenticated smoke request immediately after `login.yml`. Its job is to verify the `Authorization` header survived the folder-to-request cascade. If this assertion fails, every downstream authenticated folder will also fail — catching it here turns a cascading CI catastrophe into a single obvious root cause.

If the `/me` (or equivalent) endpoint is also exercised by a feature folder so that folder is independently runnable (e.g. `20-users/get-me.yml`), both files open with the mirror marker: `# Mirrors 00-auth/me.yml — keep both in sync when the endpoint evolves.` Without the marker, drift between the two copies is a matter of time.

```yaml
info:
  name: Me (auth smoke test)
  type: http
  seq: 2
  tags:
    - auth
    - smoke

docs: |-
  # Me — auth smoke test

  Canary for the Authorization header cascade. If this request 401s, the
  folder-level `Authorization: Bearer {{authToken}}` header in some
  authenticated folder isn't being sent — check `folder.yml` in 00-auth,
  or run with `--verbose` to see the request headers.

http:
  method: GET
  url: "{{baseUrl}}/api/me"

runtime:
  scripts:
    # This request exists to verify auth is wired up. The folder header
    # must reach this request — we do NOT delete it here.
    - type: before-request
      code: |-
        if (!bru.getVar("authToken")) {
          throw new Error("authToken missing — login must run first");
        }
  assertions:
    - expression: res.status
      operator: eq
      value: "200"
      description: "Authorization header cascade is intact"
    - expression: res.body.id
      operator: isDefined
      description: "Returns a user resource"
```

Wait — `isDefined` alone would pass on a 401 body like `{ message: "Unauthenticated." }` (see "isDefined caveat" below). The `status eq 200` assertion above is the one that actually catches the auth failure; `isDefined` is the secondary check on body shape.

### `isDefined` caveat — always pair with a status assertion

Bruno's `isDefined` operator is permissive. On a 401 where `res.body = { message: "Unauthenticated." }`, the assertion `res.body.data.id: isDefined` passes — the operator traverses missing intermediate keys without distinguishing between "defined" and "defined because the response shape is wrong". Treat `isDefined` and `isNotEmpty` as secondary checks only:

```yaml
runtime:
  assertions:
    # Primary: status must match — filters out 4xx bodies entirely.
    - expression: res.status
      operator: eq
      value: "200"
    # Secondary: body shape on the happy-path response.
    - expression: res.body.data.id
      operator: isDefined
```

Never write a `runtime.assertions` block whose only check is `isDefined` / `isNotEmpty` on a body field — a 4xx slips through.

### Auth (login) — e.g., `login.yml`

```yaml
info:
  name: Login
  type: http
  seq: 1
  tags:
    - auth
    - smoke

http:
  method: POST
  url: "{{baseUrl}}/api/auth/login"
  body:
    type: json
    data: |-
      {
        "email": "{{testUserEmail}}",
        "password": "{{testUserPassword}}"
      }

runtime:
  assertions:
    - expression: res.status
      operator: eq
      value: "200"
    - expression: res.body.token
      operator: isNotEmpty
      description: "Returns a non-empty auth token"
  scripts:
    - type: tests
      code: |-
        test("should return a string token", function() {
          const body = res.getBody();
          expect(body.token).to.be.a("string");
        });

    - type: after-response
      code: |-
        const body = res.getBody();
        if (body && body.token) {
          bru.setVar("authToken", body.token);
        }
        if (body && body.refreshToken) {
          bru.setVar("refreshToken", body.refreshToken);
        }

settings:
  encodeUrl: true
```

Note: `login.yml` sits in `00-auth/`, whose `folder.yml` intentionally omits the `Authorization` header block (the login endpoint is unauthenticated). There is no `auth: none` or `auth: inherit` directive anywhere — those are no-ops in Bruno CLI 3.2.x.

### Paginated list — e.g., `get-users-paginated.yml`

```yaml
runtime:
  assertions:
    - expression: res.status
      operator: eq
      value: "200"
  scripts:
    - type: tests
      code: |-
        test("should return pagination metadata", function() {
          const body = res.getBody();
          expect(body).to.have.property("data");
          expect(body).to.have.property("total");
          expect(body).to.have.property("page");
          expect(body).to.have.property("limit");
          expect(body.data).to.be.an("array");
        });

        test("should respect limit parameter", function() {
          const body = res.getBody();
          expect(body.data.length).to.be.at.most(body.limit);
        });
```

---

## Declarative Assertions

Use these for quick, code-free validation. They go in `runtime.assertions`.

### Common patterns

```yaml
assertions:
  # Status code
  - expression: res.status
    operator: eq
    value: "200"

  # Body property exists
  - expression: res.body.id
    operator: isDefined

  # Body property value
  - expression: res.body.status
    operator: eq
    value: "active"

  # String contains
  - expression: res.body.message
    operator: contains
    value: "success"

  # Nested property
  - expression: res.body.user.profile.name
    operator: isNotEmpty

  # Array not empty
  - expression: res.body.items
    operator: isNotEmpty

  # Array item access
  - expression: res.body.items[0].id
    operator: isDefined

  # Header check
  - expression: res.headers['content-type']
    operator: contains
    value: "application/json"

  # Response time
  - expression: res.responseTime
    operator: lt
    value: "2000"

  # Complex nested access
  - expression: res('order.items[0].price')
    operator: eq
    value: "29.99"

  # Numeric comparison
  - expression: res.body.count
    operator: gt
    value: "0"

  # Boolean check
  - expression: res.body.active
    operator: isTruthy

  # Type check
  - expression: res.body.email
    operator: isString
```

---

## Chaining Requests with Variables

Use `after-response` scripts to capture values and `before-request` scripts to inject them.

### Pattern: Auth → Create → Read → Update → Delete

**1. Login (seq: 1)** — captures `authToken`
```yaml
# after-response script:
bru.setVar("authToken", res.body.token);
```

**2. Create resource (seq: 2)** — captures `resourceId`
```yaml
# after-response script:
bru.setVar("createdResourceId", res.body.id);
```

**3. Get resource (seq: 3)** — uses `createdResourceId`
```yaml
http:
  url: "{{baseUrl}}/api/resources/{{createdResourceId}}"
```

**4. Update resource (seq: 4)** — uses `createdResourceId`
```yaml
http:
  url: "{{baseUrl}}/api/resources/{{createdResourceId}}"
  method: PUT
```

**5. Delete resource (seq: 5)** — uses `createdResourceId`
```yaml
http:
  url: "{{baseUrl}}/api/resources/{{createdResourceId}}"
  method: DELETE
```

### Capture-producer GETs hard-assert non-empty

A GET whose only purpose is to seed a downstream `bru.setVar` variable is a *producer*. Its correctness isn't "returned 200" — it's "returned at least one row so the capture actually happened". A 200 with `{data: []}` is a silent failure mode for this class of request, and defensive `if (body.data.length > 0)` guards in the `after-response` push blame onto the innocent consumer. Fix it at the source:

```yaml
# 10-reference-data/get-cities.yml — producer
runtime:
  assertions:
    - expression: res.status
      operator: eq
      value: "200"
    - expression: res.body.data
      operator: isNotEmpty
      description: "Captures firstCityId — must return at least one row"
  scripts:
    - type: after-response
      code: |-
        const body = res.getBody();
        if (body && Array.isArray(body.data) && body.data.length > 0) {
          bru.setVar("firstCityId", body.data[0].id);
        }
```

The `isNotEmpty` assertion fails loudly at the producer when the reference data isn't seeded — exactly where the operator can act. Keep the defensive `length > 0` check in the `after-response` too (cheap belt-and-braces against scripting errors), but don't rely on it as the primary signal.

### Guard chained requests against empty variables

When an upstream capture fails (network error, earlier 4xx, folder re-order), the dependent request's URL interpolates the missing variable to an empty string. `/api/projects/{{createdProjectId}}` becomes `/api/projects/` — which often matches the *collection* route with a wrong method (405) or resolves a misleading 404, and the downstream test silently passes. Always guard:

```yaml
scripts:
  - type: before-request
    code: |-
      if (!bru.getVar("createdProjectId")) {
        throw new Error("createdProjectId missing — create-project must run first");
      }
```

Throwing in `before-request` fails the request loudly instead of silently hitting the collection route.

### Conditional execution in collection runs

```javascript
// Skip request if a variable is missing
const token = bru.getVar("authToken");
if (!token) {
  bru.runner.skipRequest();
}

// Stop execution on critical failure
if (res.getStatus() === 401) {
  bru.runner.stopExecution();
}
```

### Folder execution order — numeric prefixes

The Bruno CLI runs folders in lexicographic order. That means ordering invariants — "captures must run before consumers", "teardown must run last" — have to be encoded in the folder names themselves. Relying on coincidental alphabetical ordering breaks the first time someone adds a folder whose domain name sorts before a dependency (`projects/` sorts before `reference-data/`, for example, so capturing `firstCityId` in the latter comes too late for the former).

The single rule: **every folder name starts with a two-digit numeric prefix.** The convention:

| Prefix | Role | Examples |
|--------|------|----------|
| `00-` | Authentication (login, smoke, destructive registration) | `00-auth/` |
| `10-` | Setup / reference-data captures | `10-reference-data/`, `10-setup/` |
| `20-`–`80-` | Feature domains — producers get lower numbers than their consumers | `20-companies/`, `30-company-users/`, `40-projects/` |
| `90-` | Teardown (logout, delete test data) | `90-cleanup/` |

Dependency ordering is a hard invariant: if folder X's `after-response` script captures a variable that folder Y's request uses, X's numeric prefix MUST be numerically less than Y's. After generation, run `ls /bruno/` and compare the output against the capture graph — the two must agree. Document the final order in the collection-level `docs:` block so maintainers adding a new folder can place it correctly.

Never put logout, cleanup, or any `teardown`-tagged request outside `90-cleanup/` — its `after-response` script would revoke the token for every downstream folder.

---

## Dynamic test data

Any payload value the server treats as unique — email, username, SIRET / VAT number, tenant slug, external ID, idempotency key, UUID — MUST be generated per run from Bruno's `{{$random*}}` family. A hardcoded `jean.dupont+bruno@example.com` works the first time, 422s on every subsequent run, and pollutes shared databases with duplicate rows. Even when CI excludes the request via `--exclude-tags=destructive`, maintainers running destructive requests locally will hit the same failure on their second run.

The canonical pattern: a `before-request` script calls `bru.interpolate()` on the dynamic variable and stores the result in a run-scoped `bru.setVar` variable, which the body references. This keeps the raw dynamic-variable syntax out of the body (easier to read), makes the captured value available to tests, and gives you one place to adjust the shape (e.g. prefix with `bruno+` for traceability).

```yaml
info:
  name: Register new user
  type: http
  seq: 1
  tags:
    - auth
    - destructive

docs: |-
  # Register new user

  Creates a user account and returns an OAuth token. Tagged `destructive`
  because the created user persists and the email uniqueness constraint
  prevents re-registration without cleanup.

  ## Dynamic variables used

  - `testEmail`, `testFirstName`, `testLastName`, `testSiret`
    — generated per run; captured for downstream tests.

http:
  method: POST
  url: "{{baseUrl}}/api/auth/register"
  body:
    type: json
    data: |-
      {
        "email": "{{testEmail}}",
        "firstName": "{{testFirstName}}",
        "lastName": "{{testLastName}}",
        "siret": "{{testSiret}}"
      }

runtime:
  assertions:
    - expression: res.status
      operator: eq
      value: "201"
  scripts:
    - type: before-request
      code: |-
        bru.setVar("testEmail", "bruno+" + bru.interpolate("{{$randomEmail}}"));
        bru.setVar("testFirstName", bru.interpolate("{{$randomFirstName}}"));
        bru.setVar("testLastName", bru.interpolate("{{$randomLastName}}"));
        bru.setVar("testSiret", String(Math.floor(1e13 + Math.random() * 9e13)));

    - type: after-response
      code: |-
        const body = res.getBody();
        if (body && body.token) {
          bru.setVar("authToken", body.token);
        }
        if (body && body.user && body.user.id) {
          bru.setVar("createdUserId", body.user.id);
        }

    - type: tests
      code: |-
        test("should return the created user with the submitted email", function() {
          const body = res.getBody();
          expect(body.user.email).to.equal(bru.getVar("testEmail"));
        });
```

This request sits in `00-auth/`, whose `folder.yml` omits the Authorization header. No per-request auth directive is needed.

**Useful built-ins** (documented in `scripting-api.md` and available via `bru.interpolate`):

| Variable | Yields |
|----------|--------|
| `{{$randomEmail}}` | `sample.person@example.com` (unique per call) |
| `{{$randomFirstName}}`, `{{$randomLastName}}`, `{{$randomFullName}}` | Realistic names |
| `{{$randomUUID}}` | v4 UUID |
| `{{$randomInt}}` | Random integer |
| `{{$timestamp}}` | Unix timestamp |
| `{{$isoTimestamp}}` | ISO 8601 timestamp |

For domain-specific formats Bruno doesn't provide (SIRET, VAT, BIC, IBAN, national IDs), compose them in the `before-request` script using `Math.random()` and document what you're generating in the request's `docs:` block.

**Never** reach for `Date.now()` as a poor-man's unique suffix when a named dynamic variable fits — the `$random*` family produces values that look like real test data in logs and reports, which matters when a CI failure shows up in the HTML artifact.

---

## Tag conventions

Tags drive which requests run in which context. The collection should use these consistently, and CI must exclude the ones that are unsafe to run on every push.

| Tag | Meaning | Included in full suite? |
|-----|---------|-------------------------|
| `{domain}` | Domain of the endpoint (`auth`, `users`, …). Every request gets one. | Yes |
| `smoke` | Critical-path happy request whose happy-path data exists in CI. A failure here is a real regression. | Yes |
| `contract` | Liveness-only check on a list endpoint whose creator is `destructive`-tagged. In CI the list is empty; the assertion "returned 200" proves the route is still registered, nothing more. | Yes |
| `error-case` | Validation / 401 / 404 scenarios. | Yes |
| `destructive` | Non-idempotent writes that seed real data, send emails, hit third-party CRMs, or mutate state in a way that breaks re-runs. | **No** — excluded via `--exclude-tags=destructive` in CI. |
| `manual` | Cannot run unattended (requires an emailed token, manual confirmation, 2FA code, etc.). | **No** — excluded via `--exclude-tags=manual`. |
| `teardown` | Lives in `90-cleanup/`. Runs that revoke state (logout, delete test data). | **No** — excluded via `--exclude-tags=teardown`. |
| `auth-chain` | Multi-step auth flows (e.g. `refresh-token.yml`) that don't need to run on every suite invocation. | **No** — run explicitly via `bru run 00-auth --tags=auth-chain` when testing the refresh grant specifically. |

Registration and other "create an external side-effect" endpoints MUST be tagged `destructive`. The tag is the single mechanism — do not randomize inputs to work around re-run breakage, and do not delete the requests from the collection. Keep them in, keep them tagged, let CI exclude them. Maintainers who need to hit them locally use `bru run --tags=destructive --env Development`.

---

## Error Case Testing

Create separate request files for error scenarios, tagged with `error-case`.

### Validation error (400) — `create-user-invalid.yml`

```yaml
info:
  name: Create User - Invalid Data
  type: http
  seq: 10
  tags:
    - users
    - error-case

http:
  method: POST
  url: "{{baseUrl}}/api/users"
  body:
    type: json
    data: |-
      {
        "email": "not-an-email"
      }

runtime:
  assertions:
    - expression: res.status
      operator: eq
      value: "400"
  scripts:
    - type: tests
      code: |-
        test("should return validation errors", function() {
          const body = res.getBody();
          expect(body).to.have.property("errors");
          expect(body.errors).to.be.an("array");
          expect(body.errors.length).to.be.greaterThan(0);
        });
```

### Unauthorized (401) — `get-users-unauthorized.yml`

```yaml
info:
  name: Get Users - Unauthorized
  type: http
  seq: 11
  tags:
    - users
    - error-case

http:
  method: GET
  url: "{{baseUrl}}/api/users"

runtime:
  scripts:
    # Strip the inherited Authorization header so the request actually
    # reaches the 401 branch. `auth: none` would be a no-op in Bruno CLI 3.2.x.
    - type: before-request
      code: |-
        req.deleteHeader("Authorization");
  assertions:
    - expression: res.status
      operator: eq
      value: "401"
```

### Not found (404) — `get-user-not-found.yml`

```yaml
info:
  name: Get User - Not Found
  type: http
  seq: 12
  tags:
    - users
    - error-case

http:
  method: GET
  url: "{{baseUrl}}/api/users/99999999"

runtime:
  assertions:
    - expression: res.status
      operator: eq
      value: "404"
```

---

## Chai Assertion Cheat Sheet

```javascript
// Equality
expect(value).to.equal(expected);        // strict ===
expect(value).to.eql(expected);          // deep equality
expect(value).to.not.equal(other);

// Type checking
expect(value).to.be.a("string");
expect(value).to.be.an("array");
expect(value).to.be.true;
expect(value).to.be.false;
expect(value).to.be.null;
expect(value).to.be.undefined;

// Property checks
expect(obj).to.have.property("key");
expect(obj).to.have.property("key", "value");
expect(obj).to.have.all.keys("a", "b");
expect(obj).to.have.any.keys("a", "b");
expect(obj).to.have.nested.property("a.b.c");

// String checks
expect(str).to.contain("substring");
expect(str).to.match(/regex/);
expect(str).to.have.lengthOf(5);
expect(str).to.not.be.empty;

// Number comparisons
expect(num).to.be.above(10);             // >
expect(num).to.be.at.least(10);          // >=
expect(num).to.be.below(100);            // <
expect(num).to.be.at.most(100);          // <=
expect(num).to.be.within(10, 100);       // range
expect(num).to.be.closeTo(10, 0.5);

// Array checks
expect(arr).to.be.an("array");
expect(arr).to.have.lengthOf(3);
expect(arr).to.include("item");
expect(arr).to.be.empty;
expect(arr).to.have.members([1, 2, 3]);  // same members (any order)
expect(arr).to.deep.include({id: 1});    // deep object in array

// Existence
expect(val).to.exist;
expect(val).to.not.be.null;
expect(val).to.not.be.undefined;

// oneOf (useful for status codes)
expect(status).to.be.oneOf([200, 201, 204]);
```

---

## Bruno CLI Reference

### Installation

```bash
npm install -g @usebruno/cli
```

### Running Collections

```bash
# Run entire collection
bru run

# Run specific folder
bru run users

# With environment
bru run --env Development

# With environment variable overrides
bru run --env Development --env-var API_KEY=secret123 --env-var JWT_TOKEN=abc

# Filter by tags (include)
bru run --tags=smoke

# Filter by tags (exclude)
bru run --exclude-tags=error-case

# Combine tag filters
bru run --tags=smoke,crud --exclude-tags=skip
```

### Reports

```bash
# JUnit XML (for CI systems)
bru run --reporter-junit results.xml

# JSON (for programmatic analysis)
bru run --reporter-json results.json

# HTML (for human review)
bru run --reporter-html results.html

# All three simultaneously
bru run --reporter-junit results.xml --reporter-json results.json --reporter-html results.html

# Skip sensitive headers in reports
bru run --reporter-html results.html --reporter-skip-headers "Authorization" "X-API-Key"

# Skip request/response bodies (smaller reports)
bru run --reporter-html results.html --reporter-skip-body
```

### Advanced Options

```bash
# Developer mode (enables require(), fs access)
bru run --sandbox=developer

# Data-driven testing with CSV
bru run --csv-file-path data.csv

# Data-driven testing with JSON
bru run --json-file-path data.json

# Multiple iterations
bru run --iteration-count=5

# Parallel execution
bru run --parallel

# Global environment
bru run --global-env Production

# Environment file from custom path
bru run --env-file ./environments/custom.yml
```

**Important (v3.0.0+):** Default mode is Safe Mode. Use `--sandbox=developer` if scripts need `require()` or filesystem access.

---

## CI/CD Integration

Full platform-specific workflow templates live in **`ci-templates.md`** (GitHub Actions, GitLab CI, CircleCI — including trigger-path guidance and tag-exclusion flags). This section keeps only the authoring-level tips.

### Tips for CI

- Create a dedicated `CI` environment with placeholder values, override via `--env-var`.
- Never commit real secrets in environment files — use `transient: true` and inject via CI secrets.
- Use `--tags=smoke` for fast PR checks, full collection for nightly runs.
- Use `--exclude-tags=destructive,manual,teardown` in every default CI run (see Tag conventions above).
- Use `--reporter-junit` for CI systems that understand JUnit format; pair with `--reporter-html` for human debugging.
- Widen the CI trigger paths to include backend source (routes, controllers, request validation) — not just `bruno/**`. A contract test that only runs on collection edits misses exactly the drift it's supposed to catch.
