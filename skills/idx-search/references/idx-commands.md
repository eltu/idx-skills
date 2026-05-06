# IDX Commands Cheat Sheet

Official documentation:

- README: https://github.com/eltu/idx/blob/main/README.md
- Search: https://github.com/eltu/idx/blob/main/docs/features/search.md
- Daemon: https://github.com/eltu/idx/blob/main/docs/features/daemon.md
- Status: https://github.com/eltu/idx/blob/main/docs/features/status.md

## Base Sequence

1. Run `idx status` at the start.
2. If there is no index (`no index found ... run idx init first`), ask the user whether they want to add/initialize idx in the project.
3. With an available index, run `idx daemon status`.
4. Inspect daemon status output and verify there is an active process for the current project ROOT directory.
5. If there is no active process for the current project ROOT, run `idx daemon enable <project_root>`.
6. Search using relevant keywords.

## Daemon Validation for Project ROOT

When you run `idx daemon status`, do not stop at command success.

- Read the output.
- Confirm that at least one active process maps to the current project ROOT.
- If there is no process for the current project ROOT, treat daemon as unavailable for this project and run `idx daemon enable <project_root>`.

## Missing Index (Confirmation Required)

If `idx status` returns something like:

```text
no index found under project root "/path/to/project": run idx init first
```

ask the user before any initialization:

```text
I could not find an idx index in this project. Would you like me to add/initialize idx now?
```

Only after explicit user confirmation, run:

```bash
idx init
```

## Examples

```bash
# check index status/sync
idx status

# initialize index (only with explicit user confirmation)
idx init

# check daemon status
idx daemon status

# validate there is an active process for the current project ROOT in the output

# enable daemon for current project ROOT (when not active for this root)
idx daemon enable /path/to/project

# keyword search (BM25)
idx search "validacao token jwt middleware"

# search with OR logic
idx search "oauth jwt" --operator OR

# search with AND logic
idx search "rate limit auth" --operator AND
```

## Notes

- Avoid a regex-first mindset; idx uses traditional IR with BM25 (keywords).
- Avoid natural-language question queries (for example: "where is xpto").
- If index is missing, always confirm with the user before running `idx init`.
- Always validate daemon status output for a process tied to the current project ROOT.
- Use body match only when needed.
- Use `idx sync` only under explicit user request.
