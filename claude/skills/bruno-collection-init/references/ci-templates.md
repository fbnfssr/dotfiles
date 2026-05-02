# CI/CD Templates

Run the full Bruno collection on every PR and every push to `main`. Upload the HTML report (and JUnit results) as artifacts.

**Trigger scope — read before copying a template.** A Bruno collection is a contract test: its job is to catch drift between the API implementation and the documented endpoints. A workflow that only fires on `bruno/**` changes misses exactly that — a backend PR that renames a route or tightens validation won't trigger the contract check.

Before writing the workflow, detect the project's backend source directories and include them in the trigger paths. Common patterns:

- **Laravel / PHP**: `routes/**`, `app/Http/Controllers/**`, `app/Http/Requests/**`, `config/**`
- **Node / Express / Nest**: `src/routes/**`, `src/controllers/**`, `src/modules/**`, `src/app.*`, `src/main.*`
- **Python / FastAPI / Django**: `app/**`, `*/views.py`, `*/urls.py`, `*/routers/**`
- **Go / Rust**: `cmd/**`, `internal/**`, `pkg/handlers/**` (Go); `src/routes/**`, `src/handlers/**` (Rust)

If detection is uncertain, include `bruno/**` plus the workflow file itself and flag in the Summary that the user should widen trigger paths to the project's backend source. A CI that only runs on collection edits is strictly worse than one that runs on every MR to `main`.

**Tag exclusions.** All templates below use:

```
--exclude-tags=destructive,manual,teardown
```

This keeps the default CI run idempotent: registration endpoints, endpoints requiring out-of-band input (emailed tokens), and logout/cleanup are skipped. Document the excluded tags in `/bruno/README.md` so maintainers know how to run them locally.

## Detection

Detect the CI platform, in this order:

1. `.github/workflows/` exists → **GitHub Actions**
2. `.gitlab-ci.yml` exists → **GitLab CI**
3. `.circleci/config.yml` exists → **CircleCI**
4. None of the above → default to **GitHub Actions** (most common) and flag to the user.

If multiple are present, ask the user which one(s) to target.

## GitHub Actions

Create `.github/workflows/bruno.yml`:

```yaml
name: Bruno API tests

on:
  pull_request:
    paths:
      - 'bruno/**'
      - '.github/workflows/bruno.yml'
      # Add backend source paths here so backend changes trigger the
      # contract test. Example (Laravel): routes/**, app/Http/**,
      # config/**. Example (Nest): src/**/*.controller.ts, src/**/*.module.ts.
  push:
    branches: [main]
    paths:
      - 'bruno/**'
      - '.github/workflows/bruno.yml'
      # Same backend source paths as above.

jobs:
  bruno-run:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install Bruno CLI
        run: npm install -g @usebruno/cli

      - name: Run Bruno collection
        working-directory: bruno
        env:
          API_BASE_URL: ${{ secrets.API_BASE_URL }}
          API_KEY: ${{ secrets.API_KEY }}
        run: |
          bru run --env CI \
            --env-var BASE_URL="$API_BASE_URL" \
            --env-var API_KEY="$API_KEY" \
            --exclude-tags=destructive,manual,teardown \
            --reporter-junit results.xml \
            --reporter-html results.html \
            --reporter-skip-headers "Authorization" "X-API-Key"

      - name: Upload HTML report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: bruno-report-${{ github.run_id }}
          path: bruno/results.html
          retention-days: ${{ github.ref == 'refs/heads/main' && 90 || 14 }}

      - name: Upload JUnit results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: bruno-junit-${{ github.run_id }}
          path: bruno/results.xml
          retention-days: 14
```

### Required secrets

Add these in **Settings → Secrets and variables → Actions**:

- `API_BASE_URL` — base URL for the CI-facing API instance.
- `API_KEY` — API key or service token (if the collection uses one).
- Any other secrets referenced by the `CI` environment file. Each secret needs a matching `--env-var` flag in the workflow.

## GitLab CI

Append to `.gitlab-ci.yml`:

```yaml
bruno-run:
  stage: test
  image: node:20
  rules:
    - changes:
        - bruno/**/*
        - .gitlab-ci.yml
        # Add backend source paths so backend changes trigger the
        # contract test. Example (Laravel): routes/**, app/Http/**.
  script:
    - npm install -g @usebruno/cli
    - cd bruno
    - |
      bru run --env CI \
        --env-var BASE_URL="$API_BASE_URL" \
        --env-var API_KEY="$API_KEY" \
        --exclude-tags=destructive,manual,teardown \
        --reporter-junit results.xml \
        --reporter-html results.html \
        --reporter-skip-headers "Authorization" "X-API-Key"
  artifacts:
    when: always
    expire_in: 14 days
    paths:
      - bruno/results.html
    reports:
      junit: bruno/results.xml
```

GitLab's `expire_in` is global per job; we use a uniform 14-day retention for both MR pipelines and `main` pipelines. Do not split into multiple jobs just to differentiate retention.

Configure `API_BASE_URL` and `API_KEY` under **Settings → CI/CD → Variables**, marked as *masked* and *protected* as appropriate.

## CircleCI

Append to `.circleci/config.yml`:

```yaml
version: 2.1

jobs:
  bruno-run:
    docker:
      - image: cimg/node:20.0
    steps:
      - checkout
      - run:
          name: Install Bruno CLI
          command: npm install -g @usebruno/cli
      - run:
          name: Run Bruno collection
          working_directory: bruno
          command: |
            bru run --env CI \
              --env-var BASE_URL="$API_BASE_URL" \
              --env-var API_KEY="$API_KEY" \
              --exclude-tags=destructive,manual,teardown \
              --reporter-junit results.xml \
              --reporter-html results.html \
              --reporter-skip-headers "Authorization" "X-API-Key"
      - store_artifacts:
          path: bruno/results.html
      - store_test_results:
          path: bruno/results.xml

workflows:
  api-tests:
    jobs:
      - bruno-run:
          filters:
            branches:
              only:
                - main
                - /^pull\/.*$/
```

Configure `API_BASE_URL` and `API_KEY` under **Project Settings → Environment Variables**.

## Notes

- `--reporter-skip-headers` prevents auth headers from being rendered into the HTML artifact. If the collection uses non-standard auth header names, add them here too.
- Keep both JUnit and HTML outputs: JUnit lets the CI UI show test-by-test pass/fail inline; HTML is easier to read when debugging.
- Consider a second scheduled workflow (cron, e.g. nightly) that runs the suite against staging independent of PR activity — catches environment drift that isn't triggered by collection edits.
