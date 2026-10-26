---
name: warp-workflow
description: Write a Warp terminal workflow (a reusable, named shell command) as a YAML file in the right directory. Use when the user wants to create, save, or add a Warp workflow, or asks for a reusable command to call from Warp.
---

# Warp workflow

A Warp workflow is one YAML file. On disk it appears in Command Search and the Command Palette, not in Warp Drive. No CLI or API creates Drive workflows, so end by telling the user to import the file (Warp Drive, `+` or right-click a folder, Import).

## Location

- Global (default, any repo): `~/.warp/workflows/<kebab-case-name>.yaml`
- Repo-specific (only when the command depends on that repo): `<repo>/.warp/workflows/<kebab-case-name>.yaml`

Create the directory if missing. Read an existing workflow before overwriting it.

## Format

```yaml
---
name: Human readable name
command: |-
  echo "{{greeting}} from {{dir}}"
tags:
  - git
description: One sentence on what it does and what it leaves untouched.
arguments:
  - name: greeting
    description: What to say
    default_value: hello
shells:
  - zsh
  - bash
```

- `name` and `command` are required. Everything else is optional; use `arguments: []` when there are none.
- Reference an argument in `command` as `{{name}}`; declare every one under `arguments`.
- Use a `|-` block for multi-line commands.

## Writing the command

- The command runs in the user's interactive shell. Never use `exit` (it closes the terminal); chain with `&&` or use a subshell.
- Quote paths and variables. Read lists line by line (`while IFS= read -r x`), not with `for x in $(...)`.
- For destructive commands, avoid `--force`-style flags unless asked, and say in the description what is skipped or kept.

## Verify

Parse the YAML (`ruby -ryaml -e 'YAML.load_file(ARGV[0])' <file>`). For a destructive command, dry-run it by replacing the destructive step with `echo` before saying it works.
