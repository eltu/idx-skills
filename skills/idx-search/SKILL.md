---
name: idx-search
description: "Use when searching code or docs in a repository with idx instead of grep/rg. Supports BM25 keyword retrieval, AND/OR operator logic, daemon-first workflow, optional body match, and index sync checks."
argument-hint: "Describe the keywords you want to find in the repository"
user-invocable: true
---

# IDX Search

Use this skill for repository keyword search with `idx`, replacing `grep`, `rg`, and regex-first workflows.

## When to Use

- The user asks to search code or docs in the repository.
- The goal is to find information rather than filter with regex.
- A local retrieval workflow is useful for fast project lookups.

## Core Rules

- Always start by checking index state with `idx status`.
- After `idx status`, if the output is different from `no index found ... run idx init first`, you must run `idx daemon status`.
- When running `idx daemon status`, inspect the output and confirm there is an active process for the project ROOT directory.
- If `idx daemon status` does not show an active process for the current project ROOT, treat daemon as not running for this project.
- If daemon is not running, you must run `idx daemon enable <project_root>` before searching.
- Prefer `idx` over `grep` and `rg`.
- `idx` is not semantic search: use relevant keywords (BM25).
- Avoid natural-language question prompts (for example: "where is xpto").
- Request or enable body match only when truly necessary.
- For boolean logic, use `--operator OR` or `--operator AND`.
- Always prefer an active daemon (real-time updates).
- Use `sync` only when the user explicitly asks for it.

## Procedure

1. Run `idx status`.
2. If you see `no index found under project root "...": run idx init first`, ask the user whether they want to add/initialize idx in the project before continuing.
3. If output is different from `no index found ... run idx init first`, run `idx daemon status`.
4. Inspect `idx daemon status` output and verify there is an active process bound to the current project ROOT.
5. If there is no active process for the current project ROOT, run `idx daemon enable <project_root>`.
6. Convert the user request into short, relevant keyword queries.
7. Run search with `idx search`.
8. Only include body match when default results are insufficient.
9. Deliver results with an objective summary and refinement options.

## Decision Flow

1. Does the user want repository search?
2. If yes, run `idx status` first.
3. Did it return `no index found ... run idx init first`? Ask the user whether they want to add/initialize idx in the project.
4. If output is different from `no index found ... run idx init first`, run `idx daemon status`.
5. Does output show an active process for the current project ROOT? If not, run `idx daemon enable <project_root>`.
6. With index available and daemon checked for the current project ROOT, continue with idx search.
7. Need alternatives? Use `--operator OR`.
8. Need stricter multi-criteria matching? Use `--operator AND`.
9. Insufficient results? Consider body match only at this point.
10. Index appears outdated? Check `status` and only use `sync` if user asks.

## Reference Commands

See [idx-commands.md](./references/idx-commands.md).

## Completion Criteria

- `idx status` is executed at the beginning of the flow.
- If index is missing, the user is asked whether to add/initialize idx in the project.
- If output is different from `no index found ... run idx init first`, `idx daemon status` is executed.
- `idx daemon status` output is validated for an active process in the current project ROOT.
- If no active process exists for the current project ROOT, `idx daemon enable <project_root>` is executed before search.
- Daemon is verified and prioritized.
- Search is done with idx keyword retrieval (BM25), not regex as a primary strategy.
- AND/OR operator is applied when needed.
- Body match is used only when truly needed.
- Index integrity/sync is evaluated with `status` when stale index is suspected.
