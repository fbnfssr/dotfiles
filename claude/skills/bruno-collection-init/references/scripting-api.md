# Bruno Scripting API Reference

Complete API reference for Bruno's JavaScript scripting environment.
Scripts run in a sandboxed JavaScript context (not full Node.js).
Bruno uses the Chai library for assertions in test scripts.

## Table of Contents

1. [Request Object (req)](#request-object-req)
2. [Response Object (res)](#response-object-res)
3. [Bruno Object (bru) — Variables](#bru-object--variables)
4. [Bruno Object (bru) — Environments](#bru-object--environments)
5. [Bruno Object (bru) — Runner](#bru-object--runner)
6. [Bruno Object (bru) — Utilities](#bru-object--utilities)
7. [Cookie Management](#cookie-management)
8. [Variable Interpolation](#variable-interpolation)

---

## Request Object (req)

Available in **pre-request scripts** and **test scripts**.

### URL & Method

| Method | Description |
|--------|-------------|
| `req.getUrl()` | Get the current request URL |
| `req.setUrl(url)` | Set the request URL |
| `req.getHost()` | Get hostname from URL |
| `req.getPath()` | Get path from URL |
| `req.getQueryString()` | Get raw query string |
| `req.getPathParams()` | Extract path parameters (returns object with `.toObject()`) |
| `req.getMethod()` | Get HTTP method |
| `req.setMethod(method)` | Set HTTP method |
| `req.getName()` | Get request name |
| `req.getAuthMode()` | Get current auth mode |
| `req.getTags()` | Get request tags as string array |

### Headers

| Method | Description |
|--------|-------------|
| `req.getHeader(name)` | Get header by name |
| `req.getHeaders()` | Get all headers |
| `req.setHeader(name, value)` | Set a header |
| `req.setHeaders(headersObj)` | Set multiple headers |
| `req.deleteHeader(name)` | Remove a header |
| `req.deleteHeaders([names])` | Remove multiple headers |

### Body & Settings

| Method | Description |
|--------|-------------|
| `req.getBody(options?)` | Get request body (`{raw: true}` for raw) |
| `req.setBody(body)` | Set request body |
| `req.getTimeout()` | Get timeout value |
| `req.setTimeout(ms)` | Set timeout in milliseconds |
| `req.setMaxRedirects(count)` | Set max redirects |

### Execution Context

| Method | Description |
|--------|-------------|
| `req.getExecutionMode()` | `'runner'` (collection run) or `'standalone'` |
| `req.getExecutionPlatform()` | `'app'` (desktop) or `'cli'` |
| `req.onFail(callback)` | Handle request errors (Developer Mode only, pre-request only) |

---

## Response Object (res)

Available in **post-response scripts** and **test scripts** only.

### Properties (direct access)

| Property | Description |
|----------|-------------|
| `res.status` | HTTP status code (e.g., 200, 404) |
| `res.statusText` | Status text (e.g., "OK", "Not Found") |
| `res.headers` | All response headers (object) |
| `res.body` | Response body (auto-parsed as JSON if applicable) |
| `res.responseTime` | Request duration in milliseconds |
| `res.url` | Final URL (after redirects) |

### Methods

| Method | Description |
|--------|-------------|
| `res.getStatus()` | Get status code |
| `res.getStatusText()` | Get status text |
| `res.getHeader(name)` | Get specific header |
| `res.getHeaders()` | Get all headers |
| `res.getBody()` | Get response body |
| `res.setBody(body)` | Override response body |
| `res.getResponseTime()` | Get response time in ms |
| `res.getUrl()` | Get final URL after redirects |
| `res.getSize()` | Get size in bytes → `{body, headers, total}` |

---

## Bruno Object (bru) — Variables

### Runtime Variables (highest precedence, ephemeral)

| Method | Description |
|--------|-------------|
| `bru.getVar(key)` | Get runtime variable |
| `bru.setVar(key, value)` | Set runtime variable |
| `bru.hasVar(key)` | Check if runtime variable exists |
| `bru.getAllVars()` | Get all runtime variables as object |
| `bru.deleteVar(key)` | Delete runtime variable |
| `bru.deleteAllVars()` | Delete all runtime variables |

### Scoped Variables (read-only from scripts)

| Method | Description |
|--------|-------------|
| `bru.getCollectionVar(key)` | Get collection-level variable |
| `bru.hasCollectionVar(key)` | Check if collection variable exists |
| `bru.getCollectionName()` | Get collection name |
| `bru.getFolderVar(key)` | Get folder variable |
| `bru.getRequestVar(key)` | Get request variable |
| `bru.getProcessEnv(key)` | Get `process.env` variable |

### Secret & OAuth Variables

| Method | Description |
|--------|-------------|
| `bru.getSecretVar(key)` | Get secret from configured secret manager (pattern: `<secret-name>.<key>`) |
| `bru.getOauth2CredentialVar(key)` | Get OAuth2 credential value |
| `bru.resetOauth2Credential(id)` | Reset OAuth2 credential for re-auth |

---

## Bruno Object (bru) — Environments

| Method | Description |
|--------|-------------|
| `bru.getEnvName()` | Get current environment name |
| `bru.getEnvVar(key)` | Get environment variable |
| `bru.setEnvVar(key, value, opts?)` | Set env variable (`{persist: true}` to save to disk) |
| `bru.hasEnvVar(key)` | Check if env variable exists |
| `bru.deleteEnvVar(key)` | Delete env variable |
| `bru.getAllEnvVars()` | Get all env variables as object |
| `bru.deleteAllEnvVars()` | Delete all env variables |
| `bru.getGlobalEnvVar(key)` | Get global/workspace env variable |
| `bru.setGlobalEnvVar(key, value)` | Set global env variable |
| `bru.getAllGlobalEnvVars()` | Get all global env variables |

---

## Bruno Object (bru) — Runner

Control execution flow during collection runs. These methods only work in runner context (not standalone requests).

| Method | Description |
|--------|-------------|
| `bru.setNextRequest(name)` | Jump to named request after current completes (pass `null` to stop) |
| `bru.runner.setNextRequest(name)` | Same as above |
| `bru.runner.skipRequest()` | Skip current request (pre-request script only) |
| `bru.runner.stopExecution()` | Stop the collection run entirely |

---

## Bruno Object (bru) — Utilities

| Method | Description |
|--------|-------------|
| `bru.sendRequest(options, cb?)` | Send programmatic HTTP request from script |
| `bru.sleep(ms)` | Pause execution (use with `await`) |
| `bru.interpolate(string)` | Resolve `{{variables}}` and `{{$dynamic}}` in a string |
| `bru.cwd()` | Get current working directory (collection path) |
| `bru.isSafeMode()` | `true` if Safe Mode, `false` if Developer Mode |
| `bru.runRequest(pathName)` | Execute another request by path/name (do NOT call from collection-level scripts) |
| `bru.getTestResults()` | Get test results for current request |
| `bru.getAssertionResults()` | Get assertion results for current request |
| `bru.disableParsingResponseJson()` | Disable auto JSON parsing (pre-request only) |

### bru.sendRequest Example

```javascript
const response = await bru.sendRequest({
  method: "POST",
  url: "https://api.example.com/auth/token",
  headers: { "Content-Type": "application/json" },
  data: { client_id: "...", client_secret: "..." }
});
bru.setVar("accessToken", response.data.access_token);
```

---

## Cookie Management

Create a jar with `bru.cookies.jar()`, then use methods on the instance.

| Method | Description |
|--------|-------------|
| `jar.setCookie(url, name, value)` | Set a cookie |
| `jar.setCookie(url, cookieObj)` | Set cookie with full options |
| `jar.setCookies(url, cookiesArray)` | Set multiple cookies |
| `jar.getCookie(url, name)` | Get cookie (returns object or null) |
| `jar.hasCookie(url, name)` | Check if cookie exists (returns Promise) |
| `jar.getCookies(url)` | Get all cookies for URL |
| `jar.deleteCookie(url, name)` | Delete one cookie |
| `jar.deleteCookies(url)` | Delete all cookies for URL |
| `jar.clear()` | Clear all cookies |

---

## Variable Interpolation

Use `{{variableName}}` anywhere in URLs, headers, params, and body.

### Basic Types

```javascript
bru.setVar("userId", 123);
// URL: {{baseUrl}}/users/{{userId}} → .../users/123

bru.setVar("isActive", true);
// Body: {"active": {{isActive}}} → {"active": true}
```

### Object Access (dot notation)

```javascript
bru.setVar("user", { profile: { name: "John" } });
// {{user.profile.name}} → "John"
```

### Array Access (index notation)

```javascript
bru.setVar("items", ["REST", "GraphQL"]);
// {{items[0]}} → "REST"
```

### Dynamic Variables

Use `bru.interpolate()` in scripts to resolve built-in dynamic variables:

```javascript
const name = bru.interpolate("{{$randomFirstName}}");
const email = bru.interpolate("{{$randomEmail}}");
const uuid = bru.interpolate("{{$randomUUID}}");
```

### Process Environment Variables

Access system env vars (useful for CI/CD):

```
{{process.env.API_SECRET}}
```

### Prompt Variables

Prompt user at runtime:

```
{{?Enter your API key}}
```
