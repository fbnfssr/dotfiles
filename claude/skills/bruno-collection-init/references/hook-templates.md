# Pre-commit Hook Templates

Install a pre-commit hook that validates modified Bruno YAML files parse correctly. Intentionally network-free and fast — actual API execution happens in CI.

## Detection

Detect the hook framework in use, in this order:

1. `.husky/` directory exists → **Husky**
2. `captainhook.json` exists → **CaptainHook** (common in PHP / Laravel projects)
3. `.pre-commit-config.yaml` exists → **pre-commit framework**
4. `lefthook.yml` / `lefthook.yaml` exists → **Lefthook**
5. None of the above → raw `.git/hooks/pre-commit`

If multiple frameworks are present, prefer in the order above and flag to the user which was picked.

## Shared script

All frameworks run the same validation logic. The script always lives at `scripts/validate-bruno-yaml.sh` (relative to the repo root) and must be executable. `mkdir -p scripts` if the directory doesn't exist, then `chmod +x` the file after writing.

Do not adapt the path to project-specific conventions like `bin/` or `tools/` — keeping the path fixed keeps the CaptainHook / Husky / Lefthook entries below copy-pasteable across every project this skill runs against.

```bash
#!/usr/bin/env bash
set -euo pipefail

# Validate staged Bruno collection YAML files parse correctly.
# Scope: bruno/**/*.yml and bruno/**/*.yaml
# Exits non-zero on parse error so the commit is blocked.

CHANGED=$(git diff --cached --name-only --diff-filter=ACM | grep -E '^bruno/.*\.ya?ml$' || true)
if [ -z "$CHANGED" ]; then
  exit 0
fi

echo "Validating Bruno collection YAML..."
HAS_ERRORS=0

# Prefer yq if available (fast, no node startup cost).
if command -v yq >/dev/null 2>&1; then
  PARSER="yq"
elif command -v node >/dev/null 2>&1; then
  PARSER="node"
else
  echo "  ✗ Neither yq nor node is available. Install one to enable YAML validation."
  exit 1
fi

for f in $CHANGED; do
  if [ "$PARSER" = "yq" ]; then
    if ! yq eval '.' "$f" >/dev/null 2>&1; then
      echo "  ✗ $f (YAML parse error)"
      HAS_ERRORS=1
    fi
  else
    if ! node -e "require('js-yaml').load(require('fs').readFileSync('$f','utf8'))" 2>/dev/null; then
      echo "  ✗ $f (YAML parse error)"
      HAS_ERRORS=1
    fi
  fi
done

if [ "$HAS_ERRORS" -eq 1 ]; then
  echo ""
  echo "Bruno YAML validation failed. Fix the above files before committing."
  echo "Tip: 'yq eval . <file>' or 'node -e \"require(\\'js-yaml\\').load(...)\"' will show the exact parse error."
  exit 1
fi
```

Notes on dependencies:
- `yq` is usually available via Homebrew (`brew install yq`) or system package managers.
- `js-yaml` is a transitive dependency of `@usebruno/cli`. If it isn't resolvable, install it directly: `npm install -D js-yaml`.
- The script auto-detects whichever is present; no config needed.

## Install by framework

### Husky

Append to `.husky/pre-commit` (create it if missing, `chmod +x`):

```bash
bash scripts/validate-bruno-yaml.sh
```

If `.husky/pre-commit` already exists, add the line next to the existing checks — do NOT overwrite.

### CaptainHook

Merge the entry below into the `pre-commit.actions` array in `captainhook.json` (create the key if missing; do NOT overwrite sibling hooks like `commit-msg` or `pre-push`):

```json
{
  "pre-commit": {
    "enabled": true,
    "actions": [
      {
        "action": "bash scripts/validate-bruno-yaml.sh",
        "conditions": [
          {
            "exec": "\\CaptainHook\\App\\Hook\\Condition\\FileStaged\\InDirectory",
            "args": ["bruno/"]
          }
        ]
      }
    ]
  }
}
```

Use `FileStaged\InDirectory` with `["bruno/"]`, **not** `FileStaged\OfType` with `["yml"]`. Filtering by file type fires the hook for every unrelated `.yml` edit (docker-compose, gitlab-ci, etc.) — which can spin up heavy parser containers when none of the staged files are Bruno collection files. The shell script re-filters to `bruno/**` internally, so the hook is still correct if the condition is loosened, but the directory filter keeps the no-op path fast.

After editing, run `vendor/bin/captainhook install` (or `./vendor/bin/captainhook install -f` for an existing install) so CaptainHook links the configured hooks into `.git/hooks/`.

### pre-commit framework

Add to `.pre-commit-config.yaml`:

```yaml
- repo: local
  hooks:
    - id: bruno-yaml-validate
      name: Validate Bruno collection YAML
      entry: bash scripts/validate-bruno-yaml.sh
      language: system
      files: '^bruno/.*\.ya?ml$'
      pass_filenames: false
```

`pass_filenames: false` is correct here — the script reads staged files from git itself, not from arguments.

### Lefthook

Add to `lefthook.yml`:

```yaml
pre-commit:
  commands:
    bruno-yaml-validate:
      glob: "bruno/**/*.{yml,yaml}"
      run: bash scripts/validate-bruno-yaml.sh
```

### Raw `.git/hooks/pre-commit`

Only for solo / local-only use — this path is not checked in, so teammates won't get the hook.

1. If `.git/hooks/pre-commit` already exists, append `bash scripts/validate-bruno-yaml.sh` to its end (preserve existing checks).
2. Otherwise, create `.git/hooks/pre-commit` with:

   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   bash scripts/validate-bruno-yaml.sh
   ```

3. `chmod +x .git/hooks/pre-commit`.
4. Flag to the user: recommend adopting Husky / pre-commit / Lefthook so the hook is shared.
