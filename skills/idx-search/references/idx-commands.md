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

# check index with detailed per-directory profile report
idx status --profile

# initialize index (only with explicit user confirmation)
idx init

# destroy index metadata (only with explicit user confirmation)
idx destroy

# check daemon status
idx daemon status

# validate there is an active process for the current project ROOT in the output

# enable daemon for current project ROOT (when not active for this root)
idx daemon enable /path/to/project

# disable daemon for a project
idx daemon disable /path/to/project

# watch and keep index synchronized in real time (foreground process)
idx watch

# watch with custom debounce window and file change reporting
idx watch --debounce 500ms --show-updated-files

# synchronize project indices manually (only when explicitly requested)
idx sync

# inspect index interactively (no path = interactive mode)
idx inspect

# inspect index payload for a specific file path
idx inspect path/to/file.go

# keyword search (BM25)
idx search "validacao token jwt middleware"

# search with OR logic
idx search "oauth jwt" --operator OR

# search with AND logic
idx search "rate limit auth" --operator AND

# relax AND query: fallback kicks in only when query has MORE than N terms
# (removes trailing terms progressively down to a single term)
# Example: with '>2' relaxation activates only for queries with 3+ terms
idx search "func abc x y int 10" --operator AND --relaxation ">2"

# search with path filter
idx search "handler" --path internal/api

# search with file extension filter (go or .go are both accepted)
idx search "handler" --ext go
idx search "handler" --ext .go

# combine path and extension filters
idx search "handler" --path internal/api --ext go

# metadata-only search (no query terms): find all files in a path
idx search --path internal/api

# metadata-only search: find all files of a given extension
idx search --ext go

# combine metadata filters without query terms
idx search --path internal/api --ext go

# limit results to top 5 files
idx search "cache invalidation" --size 5

# paginate: skip first 5 ranked files
idx search "cache invalidation" --size 5 --from 5

# show only matched file paths
idx search "middleware" --files-only

# show only directly matched lines (no surrounding context)
idx search "jwt" --matches-only

# show N context lines around each match
idx search "jwt" --context 3

# include ranking score metadata in output
idx search "jwt" --explain

# output results as JSON
idx search "jwt" --format json

# output results as pretty-printed JSON
idx search "jwt" --format json --json-pretty
```

## Search Flags Reference

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--operator` | string | `AND` | Boolean logic for multi-term queries: `AND` or `OR` |
| `--relaxation` | string | — | Relax AND query with trailing-term fallback. Format: `>N`. Activates **only when query has more than N terms**; removes trailing terms progressively down to a single term. |
| `--path` | stringArray | — | Filter results by metadata path (repeatable) |
| `--ext` | stringArray | — | Filter by file extension, e.g. `go` or `.go` (repeatable, combinable with `--path`) |
| `--size` | int | — | Limit results to top N files |
| `--from` | int | — | Skip the first N ranked files (pagination) |
| `--files-only` | bool | false | Show only matched file paths |
| `--matches-only` | bool | false | Show only directly matched lines |
| `--context` | int | — | Number of context lines around matches |
| `--explain` | bool | false | Include ranking metadata (score) |
| `--format` | string | `text` | Output format: `text` or `json` |
| `--json-pretty` | bool | false | Pretty-print JSON output |

## Notes

- Avoid a regex-first mindset; idx uses traditional IR with BM25 (keywords).
- Avoid natural-language question queries (for example: "where is xpto").
- If index is missing, always confirm with the user before running `idx init`.
- Always validate daemon status output for a process tied to the current project ROOT.
- Use `--relaxation` to soften strict AND queries when multi-term matches are sparse. **Important:** relaxation only activates when the query has more than N terms; with `>1`, requires at least 2 terms to activate.
- Use `--path` to narrow results to a specific directory or file prefix.
- Use `--ext` to filter by file extension (e.g. `go`, `.go`). Repeatable and combinable with `--path`.
- Use `--path` and/or `--ext` without query terms for metadata-only search (browsing by location or type).
- Use `--files-only` for a quick overview of affected files before diving into matches.
- Use `--explain` only for debugging ranking; avoid in normal search flows.
- Use `--format json` when output needs to be processed programmatically.
- Use `idx sync` only under explicit user request.
- Use `idx destroy` only with explicit user confirmation.
- `idx watch` runs in the foreground; prefer daemon for background monitoring.
