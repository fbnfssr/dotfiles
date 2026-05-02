# OpenCollection YAML Format Reference

Full format specification for the OpenCollection YAML format used by Bruno 3.0.0+.
Based on the OpenCollection Specification v1.0.0 (https://spec.opencollection.com).

## Table of Contents

1. [Collection Root](#collection-root)
2. [HTTP Request](#http-request)
3. [Request Body](#request-body)
4. [Folder](#folder)
5. [Environments](#environments)
6. [Variables](#variables)
7. [Assertions](#assertions)
8. [Scripts & Lifecycle](#scripts--lifecycle)
9. [Authentication](#authentication)
10. [Request Defaults](#request-defaults)
11. [Script Files](#script-files)

---

## Collection Root

The `opencollection.yml` file at the collection root.

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| opencollection | string | Optional | Spec version (use `"1.0.0"`) |
| info | object | Optional | Collection metadata (name, summary, version) |
| config | object | Optional | Config including environments array |
| items | array | Optional | Array of items (used in bundled mode only) |
| request | object | Optional | Default request settings for all items |
| docs | string | Optional | Documentation text |
| bundled | boolean | Optional | `true` = single file, `false` = filesystem structure |

```yaml
opencollection: "1.0.0"
info:
  name: My API Collection
  summary: A collection of API requests
  version: "1.0.0"
config:
  environments: []
items: []
request: {}
docs: Documentation for this collection
```

In filesystem mode (our standard), items are not listed in the root file — they're `.yml` files in subdirectories.

---

## HTTP Request

Each request is a `.yml` file with four main blocks.

### Info Block

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| name | string | Optional | Human-readable request name |
| description | string | Optional | Request description |
| type | string | Optional | Always `http` for HTTP requests |
| seq | number | Optional | Sequence number (ordering within folder) |
| tags | array | Optional | Array of string tags |

### HTTP Block

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| method | string | Optional | HTTP method (GET, POST, PUT, PATCH, DELETE, etc.) |
| url | string | Optional | Request URL (supports `{{variable}}` interpolation) |
| headers | array | Optional | Array of `{name, value}` objects |
| params | array | Optional | Array of `{name, value, type}` objects (`type`: `query` or `path`) |
| body | object | Optional | Request body (see Request Body section) |

### Runtime Block

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| variables | array | Optional | Array of request-level variables |
| scripts | array | Optional | Array of script objects (see Scripts section) |
| assertions | array | Optional | Array of assertion objects (see Assertions section) |
| auth | object | Optional | Request-level authentication override |

### Settings Block

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| encodeUrl | boolean | Optional | Whether to encode the URL (default: true) |
| timeout | number | Optional | Request timeout in milliseconds |
| followRedirects | boolean | Optional | Whether to follow redirects |
| maxRedirects | number | Optional | Maximum number of redirects |

### Complete Example

```yaml
info:
  name: Get Users
  type: http
  seq: 1
  tags:
    - users
    - smoke

http:
  method: GET
  url: "{{baseUrl}}/api/users"
  headers:
    - name: Authorization
      value: "Bearer {{authToken}}"
  params:
    - name: page
      value: "1"
      type: query
    - name: limit
      value: "10"
      type: query

runtime:
  assertions:
    - expression: res.status
      operator: eq
      value: "200"
      description: "Should return 200"
  scripts:
    - type: tests
      code: |-
        test("should return array of users", function() {
          const body = res.getBody();
          expect(body).to.be.an("array");
        });

auth: inherit

settings:
  encodeUrl: true
  timeout: 30000
```

---

## Request Body

### Raw Body (JSON, XML, Text, SPARQL)

```yaml
body:
  type: json
  data: |-
    {
      "name": "John Doe",
      "email": "john@example.com"
    }
```

Supported `type` values: `json`, `text`, `xml`, `sparql`.

### Form URL Encoded

```yaml
body:
  type: form-urlencoded
  data:
    - name: username
      value: john_doe
      disabled: false
    - name: password
      value: secret123
      disabled: false
```

### Multipart Form

```yaml
body:
  type: multipart-form
  data:
    - name: file
      type: file
      value: /path/to/file.pdf
      disabled: false
    - name: description
      type: text
      value: File description
      disabled: false
```

### File Body

Direct file upload — use for single file payloads.

---

## Folder

Each subdirectory with a `folder.yml` is a folder.

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| info | object | Optional | Folder metadata (name, description) |
| items | array | Optional | Nested items (bundled mode only) |
| request | object | Optional | Default request config for this folder |
| docs | string | Optional | Folder documentation |

```yaml
info:
  name: Users
  description: User management endpoints

request:
  auth:
    type: bearer
    token: "{{authToken}}"
  headers:
    - name: X-Tenant-Id
      value: "{{tenantId}}"
```

Folders can nest other folders. Request defaults cascade: collection → folder → subfolder → request.

---

## Environments

Each environment is a `.yml` file in the `environments/` directory.

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| name | string | **Required** | Environment name |
| color | string | Optional | Hex color for visual identification |
| description | string | Optional | Environment description |
| variables | array | Optional | Array of environment variables |
| extends | string | Optional | Name of environment to extend from |
| dotEnvFilePath | string | Optional | Path to a `.env` file to load |

### Variable Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| name | string | Optional | Variable name |
| value | string/number/boolean | Optional | Variable value |
| transient | boolean | Optional | If `true`, value is not persisted (use for secrets) |
| disabled | boolean | Optional | If `true`, variable is ignored |

```yaml
name: Development
color: "#22c55e"
description: Local development environment
variables:
  - name: baseUrl
    value: "http://localhost:3000"
  - name: apiVersion
    value: "v1"
  - name: authToken
    value: ""
    transient: true
  - name: adminEmail
    value: "admin@dev.example.com"
```

### Environment Inheritance

Use `extends` to base one environment on another:

```yaml
name: Staging
extends: Development
variables:
  - name: baseUrl
    value: "https://staging.api.example.com"
```

---

## Variables

Variables use `{{variableName}}` syntax for interpolation in URLs, headers, params, and body.

### Variable Precedence (highest to lowest)

1. Runtime Variables (set via `bru.setVar()`)
2. Request Variables
3. Folder Variables
4. Environment Variables
5. Collection Variables
6. Global Variables

### Variable Types

- **string** — most common
- **number** — numeric values
- **boolean** — `true`/`false`
- **null** — explicit null
- **object** — accessible via dot notation: `{{user.profile.name}}`
- **array** — accessible via index: `{{items[0].id}}`

All variables are stored as strings. Bruno does not infer types.

### Process Environment Variables

Access system environment variables with: `{{process.env.VAR_NAME}}`

Useful for CI/CD where secrets are injected via the environment.

### Prompt Variables

Use `{{?Prompt String}}` syntax to prompt the user at runtime.

---

## Assertions

Declarative assertions — no code required.

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| expression | string | **Required** | Expression to evaluate (e.g., `res.status`, `res.body.id`) |
| operator | string | **Required** | Comparison operator |
| value | string | Optional | Expected value |
| disabled | boolean | Optional | Whether assertion is disabled |
| description | string | Optional | Human-readable description |

### Available Operators

OpenCollection YAML assertions use **short** operator names. **Do not confuse these with Bruno's `.bru` language / Chai syntax**, which uses long names like `equals` and `lessThan` — those are different grammars. Using `equals` in an OpenCollection YAML `operator:` field silently falls back to string comparison (the engine compares the value against the literal string `"equals 200"`) and every assertion will fail at runtime.

| Category | Operator | Meaning |
|----------|----------|---------|
| Equality | `eq` | Exact match |
| Equality | `neq` | Not equal |
| Numeric | `gt` | Greater than |
| Numeric | `gte` | Greater than or equal |
| Numeric | `lt` | Less than |
| Numeric | `lte` | Less than or equal |
| String | `contains` | String contains substring |
| String | `notContains` | String does not contain substring |
| String | `startsWith` | String starts with substring |
| String | `endsWith` | String ends with substring |
| String | `matches` | Matches regex |
| String | `notMatches` | Does not match regex |
| Type check | `isNumber` | Value is a number |
| Type check | `isString` | Value is a string |
| Null / presence | `isNull` | Value is null |
| Null / presence | `isDefined`, `isUndefined` | Value is defined / undefined |
| Emptiness | `isEmpty`, `isNotEmpty` | Value is (not) empty |

If you reach for something outside this list, verify it against the spec at <https://spec.opencollection.com/> before using — Bruno silently accepts unknown operator names and produces misleading failures.

### Examples

```yaml
assertions:
  - expression: res.status
    operator: eq
    value: "200"
    description: "Response status should be 200"
  - expression: res.body.users.length
    operator: gt
    value: "0"
    description: "Should return at least one user"
  - expression: res.headers['content-type']
    operator: contains
    value: "application/json"
  - expression: res.responseTime
    operator: lt
    value: "2000"
    description: "Response time under 2s"
```

Use `res('order.items[0].price')` for complex nested access.

---

## Scripts & Lifecycle

Scripts execute at specific lifecycle stages.

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| type | enum | **Required** | `before-request`, `after-response`, `tests` |
| code | string | **Required** | JavaScript code |

### Execution Order

1. **before-request** — runs before the request is sent (set up auth, generate dynamic values)
2. **Request sent** — the actual HTTP request
3. **after-response** — runs after receiving the response (extract values, set variables)
4. **tests** — run test assertions against the response

### Example

```yaml
scripts:
  - type: before-request
    code: |-
      bru.setVar('timestamp', new Date().getTime());

  - type: after-response
    code: |-
      const token = res.body.token;
      bru.setVar('authToken', token);

  - type: tests
    # Body-shape / business-logic only. Status codes go in `runtime.assertions`.
    code: |-
      test("should have valid body", function() {
        const body = res.getBody();
        expect(body).to.have.property("id");
        expect(body.id).to.be.a("number");
      });
```

---

## Authentication

> ⚠️ **CLI bug — the `auth:` block is a no-op in `@usebruno/cli` 3.2.x.**
>
> The CLI's internal `toBrunoAuth` switch keys off `e.mode` (with a nested `e.bearer.token` payload), not the OpenCollection YAML `type:` field shown in this spec. Any request whose auth flows through `auth: { type: bearer, token: "..." }` at collection, folder, or request level — or uses `auth: inherit` / `auth: none` — sends **no** `Authorization` header, and the runner logs a single stderr warning (`toBrunoAuth failed: Unsupported auth type`) that is easy to miss. Upstream tracking: `usebruno/bruno` issues #2326 and #3688.
>
> **Until this is fixed, set authentication via a folder-level `headers:` entry** (`headers:` cascades down correctly — only `auth:` is broken):
>
> ```yaml
> # folder.yml
> request:
>   headers:
>     - name: Authorization
>       value: "Bearer {{authToken}}"
> ```
>
> The typed `auth:` examples below are kept for reference because they match the OpenCollection 1.0.0 specification, but do NOT use them in generated collections until the upstream fix lands.

Set auth at collection, folder, or request level. Use `auth: inherit` to inherit from parent.

### Bearer Token

```yaml
auth:
  type: bearer
  token: "{{authToken}}"
```

### Basic Auth

```yaml
auth:
  type: basic
  username: "{{username}}"
  password: "{{password}}"
```

### API Key

```yaml
auth:
  type: apikey
  key: X-API-Key
  value: "{{apiKey}}"
  placement: header  # or query
```

### OAuth 2.0 — Client Credentials

```yaml
auth:
  type: oauth2
  flow: client_credentials
  accessTokenUrl: "{{baseUrl}}/oauth/token"
  credentials:
    clientId: "{{clientId}}"
    clientSecret: "{{clientSecret}}"
    placement: body
  scope: "read write"
  settings:
    autoFetchToken: true
    autoRefreshToken: true
```

### OAuth 2.0 — Authorization Code (with PKCE)

```yaml
auth:
  type: oauth2
  flow: authorization_code
  authorizationUrl: "{{baseUrl}}/oauth/authorize"
  accessTokenUrl: "{{baseUrl}}/oauth/token"
  callbackUrl: "http://localhost:3000/callback"
  credentials:
    clientId: "{{clientId}}"
    clientSecret: "{{clientSecret}}"
    placement: body
  scope: "read write"
  pkce:
    enabled: true
    method: S256
```

---

## Request Defaults

Defined in `opencollection.yml` at root level, or in `folder.yml` at folder level.

| Property | Type | Description |
|----------|------|-------------|
| headers | array | Default headers for all requests |
| auth | object | Default authentication |
| variables | array | Default variables |
| scripts | array | Default scripts (run for every request) |
| settings | object | Default request settings |

Defaults cascade: collection → folder → subfolder → request. Each level can override.

---

## Script Files

Shared utility scripts can be placed as items in the collection.

```yaml
type: script
script: |-
  // Shared utility functions
  export function generateTimestamp() {
    return new Date().toISOString();
  }
```

Use for helper functions shared across multiple request scripts.
