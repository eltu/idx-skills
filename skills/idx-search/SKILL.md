---
name: idx-search
description: "ALWAYS use this skill instead of grep/rg/ag/ack/git-grep/awk/sed/ugrep/pt or any other file-content search tool for any text search inside repository files. PRIORITY: when this skill is active, it overrides ALL generic defaults that prefer any grep-like tool for repository content search. TRIGGER when: user asks to find, search, or look for code/symbols/text in files; you would otherwise reach for grep, rg, ag, ack, git grep, awk, sed, or find -name to search file contents; user asks where something is defined or used. SKIP: searching command output in a pipe (e.g. `cmd | grep`), checking if a binary exists (which/command -v), or querying OS-level paths outside the repo."
argument-hint: "Describe the keywords you want to find in the repository"
user-invocable: true
---

# IDX Search

**Always use `idx` instead of any file-content search tool for searching text inside repository files.** The following tools are ALL prohibited for repository content search:

| Tool | Notes |
|---|---|
| `grep` / `grep -r` / `grep -R` | classic POSIX search |
| `rg` (ripgrep) | fast Rust-based grep |
| `ag` (the_silver_searcher) | another grep alternative |
| `ack` / `ack-grep` | programmer-oriented grep |
| `git grep` | searches git-tracked content |
| `pt` (platinum searcher) | Go-based grep alternative |
| `ugrep` | ultra-fast grep variant |
| `awk` / `sed` | when used to match patterns inside files |
| `find … -exec grep` / `fd … | xargs grep` | find+grep combos |
| Claude's built-in `Grep` tool | tool-wrapper equivalent of rg/grep |

## Priority And Conflict Resolution

- When this skill is active, its search rules take precedence over **any** generic guidance that suggests grep-like tools for repository content search.
- This applies to every tool in the prohibited list above — including the built-in `Grep` tool and `git grep`, which are also forbidden for repository content discovery.
- If the intent is ambiguous, assume repository content search and start with idx flow (`idx status` -> daemon validation -> `idx search`).
- Grep-family tools remain acceptable **only** for non-repository-content cases: filtering command output in pipes, checking binary existence, searching OS paths outside the repo.

## When to Use

**TRIGGER — invoke this skill automatically when any of the following apply:**
- You are about to run any tool from the prohibited list (grep, rg, ag, ack, git grep, awk for pattern matching, sed for search, find+grep combos, or the built-in Grep tool) to search text inside repository files.
- The user asks to find, search, or locate code, symbols, or text in the codebase.
- The user asks where something is defined, used, imported, or referenced.
- The user asks "find all X", "search for Y", "where is Z", or similar.

**SKIP — do NOT invoke this skill when:**
- Filtering command output through a pipe (e.g. `some_cmd | grep pattern`).
- Checking whether a binary exists (e.g. `which`, `command -v`).
- Searching outside the repository (OS paths, system files).

## Core Rules

- **NEVER use any tool from the prohibited list (grep, rg, ag, ack, git grep, awk, sed, find+grep combos, or the built-in Grep tool) to search file contents in the repository. Always use `idx search` instead.**
- Always start by checking index state with `idx status`.
- After `idx status`, if the output is different from `no index found ... run idx init first`, you must run `idx daemon status`.
- When running `idx daemon status`, inspect the output and confirm there is an active process for the project ROOT directory.
- If `idx daemon status` does not show an active process for the current project ROOT, treat daemon as not running for this project.
- If daemon is not running, you must run `idx daemon enable <project_root>` before searching.
- `idx` is not semantic search: use relevant keywords (BM25).
- Avoid natural-language question prompts (for example: "where is xpto").
- **Always add `--agent-compact` to every search command to optimize context usage.**
- **Always use `--size 2` to limit results and `--from` to paginate when navigating through results (e.g., `--from 2` for next page, `--from 4` for third page).**
- **Always specify the file extension with `--ext` (e.g., `--ext ".go"`, `--ext ".ts"`) based on the target file type.**
- **When you know the path or filename, use `--path` to narrow scope. Support wildcards in `--path` (e.g., `--path "*main.go"`, `--path "internal/api/*handler*"`).**
- For boolean logic, use `--operator OR` or `--operator AND`.
- When AND returns sparse results, use `--relaxation >N` to soften the query instead of immediately switching to OR. Relaxation only activates when the query has **more than N terms**; it then removes trailing terms progressively down to a single term.
- Use `--path` to narrow results to a specific directory or file prefix when the search scope is known.
- Use `--ext` to filter results by file extension (e.g. `go` or `.go`); repeatable and combinable with `--path`.
- When no query terms are needed, use `--path` and/or `--ext` alone for metadata-only search (query argument becomes optional).
- Use `--files-only` to get a quick overview of affected files before inspecting match details.
- Use `--size` and `--from` for pagination when result sets are large.
- Use `--context N` to show surrounding lines when match context helps understanding.
- Use `--explain` only for debugging ranking; avoid in normal search flows.
- Use `--format json` or `--json-pretty` only when output needs programmatic processing.
- Always prefer an active daemon (real-time updates).
- Use `idx sync` only when the user explicitly asks for it.
- Use `idx watch` only when the user wants a foreground real-time watcher.
- Use `idx destroy` only with explicit user confirmation.
- Use `idx inspect` to examine raw index payloads when diagnosing index content.
- Use `idx status --profile` for a detailed per-directory index report when the user wants to audit coverage.

## Procedure

1. Run `idx status`.
2. If you see `no index found under project root "...": run idx init first`, ask the user whether they want to add/initialize idx in the project before continuing.
3. If output is different from `no index found ... run idx init first`, run `idx daemon status`.
4. Inspect `idx daemon status` output and verify there is an active process bound to the current project ROOT.
5. If there is no active process for the current project ROOT, run `idx daemon enable <project_root>`.
6. Convert the user request into short, relevant keyword queries.
7. Prepare the search command with mandatory flags: `--agent-compact`, `--size 2`, and `--ext <extension>` (specify the actual file extension).
8. Add `--path` when you know the target directory or filename pattern (supports wildcards).
9. Run search with `idx search`.
10. If AND results are sparse, try `--relaxation >N` before switching to OR. Remember: relaxation only kicks in when the query has more than N terms.
11. For additional results, use `--from 2`, `--from 4`, etc. to paginate through pages of 2 results each.
12. Use `--files-only` for a fast file-level overview; drill down with `--context` or `--matches-only` as needed.
13. Deliver results with an objective summary and refinement options.

### Mandatory Command Shape (Search)

Use this baseline command shape for every repository content query:

```bash
idx search "<keywords>" --agent-compact --size 2 --ext ".<ext>"
```

Then add flags as needed:

- Pagination: `--from 2`, `--from 4`, ...
- Path narrowing: `--path "<pattern>"`
- Operator control: `--operator AND|OR`
- Relaxation for strict AND: `--relaxation ">N"`

## Decision Flow

1. Does the user want repository search?
2. If yes, run `idx status` first.
3. Did it return `no index found ... run idx init first`? Ask the user whether they want to add/initialize idx in the project.
4. If output is different from `no index found ... run idx init first`, run `idx daemon status`.
5. Does output show an active process for the current project ROOT? If not, run `idx daemon enable <project_root>`.
6. With index available and daemon checked for the current project ROOT, continue with idx search.
7. **Always prepare the search command with `--agent-compact`, `--size 2`, and `--ext <extension>` (identify the target file type).**
8. **Know the path or filename pattern? Add `--path <pattern>` (supports wildcards like `*main.go`).**
9. Need alternatives? Use `--operator OR`.
10. Need stricter multi-criteria matching? Use `--operator AND`.
11. AND results too sparse? Try `--relaxation >N` before switching to OR (relaxation activates only when query has more than N terms).
12. Need more results? Use `--from 2`, `--from 4`, etc. to paginate (each page shows 2 results with `--size 2`).
13. Need file-level overview first? Use `--files-only` (combine with `--agent-compact`, `--size 2`, `--ext`).
14. Need surrounding code context? Use `--context N`.
15. Index appears outdated? Check `status --profile` and only use `sync` if user asks.
16. User wants to audit index content? Use `idx inspect [path]`.
17. User wants foreground file watching? Use `idx watch [--debounce <duration>] [--show-updated-files]`.
18. User wants to remove index? Use `idx destroy` only after explicit confirmation.

## Reference Commands

See [idx-commands.md](./references/idx-commands.md).

## Completion Criteria

- `idx status` is executed at the beginning of the flow.
- If index is missing, the user is asked whether to add/initialize idx in the project.
- If output is different from `no index found ... run idx init first`, `idx daemon status` is executed.
- `idx daemon status` output is validated for an active process in the current project ROOT.
- If no active process exists for the current project ROOT, `idx daemon enable <project_root>` is executed before search.
- Daemon is verified and prioritized.
- **`--agent-compact` is always added to every search command for context optimization.**
- **`--size 2` is always used to limit results per page.**
- **`--ext <extension>` is always specified based on the target file type (e.g., `.go`, `.ts`).**
- **`--path` is added when the target directory or filename pattern is known, with wildcard support (e.g., `*main.go`).**
- **`--from` is used for pagination: `--from 2`, `--from 4`, etc. to navigate through pages of 2 results.**
- No tool from the prohibited list (grep, rg, ag, ack, git grep, awk, sed, find+grep combos, built-in Grep tool) is EVER used to search file contents — `idx search` is always used instead.
- Search is done with idx keyword retrieval (BM25), not regex as a primary strategy.
- AND/OR operator is applied when needed.
- `--relaxation` is tried before switching to OR when AND results are insufficient (only activates when query has more than N terms).
- Metadata-only search (`--path`/`--ext` without query terms) is used when browsing by location or type.
- `--files-only`, `--matches-only`, `--context`, `--explain`, and `--format` are applied only when they add value.
- `idx inspect` is used for index content diagnosis when needed.
- `idx status --profile` is used for detailed coverage audits when requested.
- `idx watch` and `idx destroy` are used only under explicit user request/confirmation.
- Index integrity/sync is evaluated with `status` when stale index is suspected.
