# copilot-instructions

## Purpose

`pipsb` is a small Stata package that loads **test-only** PIP sandbox datasets from a private GitHub data repository directly into Stata memory.

- Package repo: `GPID-WB/pipsb`
- Private data repo: `GPID-WB/pip-sandbox`
- Warning to preserve in docs and messaging: the data is fake/testing data and is not official World Bank output.

The package should stay lightweight: download, validate, and load data into memory without saving permanent package-managed data files in the repo.

## Current package structure

Package-relevant files in this repo:

- `pipsb.ado` — main command implementation and private helper programs
- `pipsb.sthlp` — Stata help file
- `pipsb.pkg` — package manifest
- `stata.toc` — Stata package index entry
- `README.md` — GitHub-facing usage/setup notes
- `copilot-instructions.md` — this maintenance note
- `.gitignore` — ignore local development/test artifacts

Local log files and other ad hoc test artifacts should not be committed.

## User-facing behavior

Main command:

```stata
pipsb [, ppp_year(integer 2021) filename(string) release(string) listreleases]
```

Behavior decisions already taken:

1. `ppp_year()` supports `2017` and `2021`.
2. `release()` defaults to `latest`.
3. `pipsb, listreleases` lists available releases and exits.
4. If `filename()` is omitted, `pipsb` lists only `.dta` files for the requested `ppp_year()` and exits.
5. File discovery is **not hardcoded** anymore; it comes from `data_catalog.csv` at the root of the selected release.
6. Only catalog rows with `extension == "dta"` are relevant for listing/validation.
7. Downloads should target the selected release tag, not the branch tip.

## Data access design

`pipsb` authenticates with GitHub using the global macro:

```stata
global GPID_GITHUB_TOKEN "..."
```

Implementation assumptions and constraints:

- The token must have at least `Contents: Read` on `GPID-WB/pip-sandbox`.
- The current implementation is Windows-only.
- Downloads use `curl.exe` plus the GitHub API.
- Data files are fetched through the GitHub Contents API with `Accept: application/vnd.github.raw+json`.
- Release metadata is fetched through the GitHub Releases API with `Accept: application/vnd.github+json`.
- Release tags are programmatically generated timestamps such as `202603131536`.
- In practice, newer tags should sort chronologically because they are generated programmatically, but the code currently asks GitHub for the latest release rather than inferring it locally.

## Internal implementation outline

`pipsb.ado` is intentionally split into a short public entry point and private helpers prefixed with `_`.

Current helpers:

- `_pipsb_validate_environment`
  - Checks `GPID_GITHUB_TOKEN`
  - Enforces Windows-only support

- `_pipsb_fetch_github`
  - Wraps authenticated `curl.exe` calls
  - Handles HTTP status parsing and common error messages

- `_pipsb_resolve_release`
  - Accepts a specific `release()` value unchanged
  - Resolves `latest` through `repos/{owner}/{repo}/releases/latest`

- `_pipsb_list_releases`
  - Fetches the releases list
  - Extracts `tag_name` values from the JSON response

- `_pipsb_get_catalog`
  - Downloads `data_catalog.csv` from the selected release

- `_pipsb_list_files`
  - Imports the catalog into Stata
  - Filters to `.dta` plus requested `ppp_year()`
  - Displays `file_name`, `label`, and `last_modified` when available

- `_pipsb_validate_filename`
  - Ensures the requested `filename()` exists in the filtered catalog

## Catalog expectations

The code expects `data_catalog.csv` to have at least:

- `ppp_year`
- `file_name`
- `label`
- either `extension` or `ext`

Optional but used for nicer display:

- `last_modified`

Example shape:

```csv
ppp_year,file_name,extension,label,last_modified
2017,aggregates,dta,Regional aggregates (Stata),2026-03-13 15:19:30
2017,lyears,dta,Lineup / fill gaps estimates (Stata),2026-03-13 15:11:50
2017,syears,dta,Survey-year estimates (Stata),2026-03-13 14:57:49
2021,aggregates,dta,Regional aggregates (Stata),2026-03-12 14:32:40
2021,lyears,dta,Lineup / fill gaps estimates (Stata),2026-03-12 14:29:02
2021,syears,dta,Survey-year estimates (Stata),2026-03-12 14:19:26
```

## Testing notes captured during implementation

Observed and fixed during local Stata batch testing:

1. `listreleases` originally failed because PPP validation ran before the `listreleases` exit path.
2. Some helper option names used underscores and had to be renamed to forms like `repoowner`, `reponame`, and `pppyear` for Stata `syntax` parsing.
3. The catalog tempfile originally vanished because it was allocated inside a helper; the caller now owns the tempfile and passes it into `_pipsb_get_catalog`.
4. Intermediate filtering output from catalog validation/listing was suppressed with `quietly` to keep the command output clean.

Smoke tests run successfully in Stata on 2026-03-13:

- `pipsb, listreleases`
- `pipsb`
- `pipsb, filename(syears)`
- `pipsb, ppp_year(2017) filename(aggregates) release(202603131536)`

Observed successful outputs during testing included:

- latest release listed as `202603131536`
- latest `syears` load with `7,752` observations
- `2017` `aggregates` load with `1,380` observations

These counts are test-run observations, not interface guarantees.

## Documentation decisions

Documentation should consistently state:

- install the Stata package from `GPID-WB/pipsb`
- data downloads happen from `GPID-WB/pip-sandbox`
- `release()` defaults to latest release
- `listreleases` is available
- omitted `filename()` lists available `.dta` files only for the selected `ppp_year()`

## Maintenance guidance

When changing this package:

1. Keep the public `pipsb` program short.
2. Put new reusable internal logic in private `_pipsb_*` helpers.
3. Avoid hardcoding catalog contents or release tags.
4. Do not commit local tokens, logs, or temporary debugging files.
5. Prefer updating `README.md` and `pipsb.sthlp` together when behavior changes.
6. Preserve the testing-data warning in user-facing output and docs.

## Non-goals

- This package is not meant to ship the datasets themselves.
- This package is not for official analytical production use.
- This package currently does not aim to support non-Windows authenticated download flows.