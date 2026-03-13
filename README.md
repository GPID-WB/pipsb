# pipsb

`pipsb` installs from `GPID-WB/pipsb` and loads test `.dta` files from the private data repository `GPID-WB/pip-sandbox` directly into Stata memory.

By default, `pipsb` uses the latest GitHub release from the data repository. It reads `data_catalog.csv` from the root of that release, filters the catalog to `.dta` files for the requested `ppp_year()`, and then downloads the selected dataset.

## Installation

`pipsb` can be installed separately from the private data repository:

```stata
net install github, from("https://haghish.github.io/github/")
github install GPID-WB/pipsb
```

## Token setup

Each user needs their own fine-grained GitHub personal access token.

Create the token from your personal GitHub account:

1. Profile photo
2. Settings
3. Developer settings
4. Personal access tokens
5. Fine-grained tokens
6. Generate new token

Recommended settings:

1. Resource owner: `GPID-WB`
2. Repository access: `GPID-WB/pip-sandbox`, or all repositories if needed
3. Repository permissions: `Contents = Read-only`
4. Expiration: a reasonable period such as 90 or 180 days

## Store the token in Stata

Add the token to your personal `profile.do`:

```stata
global GPID_GITHUB_TOKEN "your_token_here"
```

Then restart Stata.

To verify that the token is available:

```stata
display "$GPID_GITHUB_TOKEN"
```

## Examples

List the releases available in the private data repository:

```stata
pipsb, listreleases
```

> **Warning**
> These are **NOT** official PIP releases. They are sandbox-data releases created before an official release.

List the available `.dta` files for the default PPP year in the latest release:

```stata
pipsb
```

Load a dataset from the latest release:

```stata
pipsb, filename(syears)
```

Load a dataset from a specific release tag:

```stata
pipsb, ppp_year(2017) filename(aggregates) release(202603131536)
```

## Troubleshooting

- If the token is not found, check `profile.do` and restart Stata.
- If you get `401` or `403`, confirm the token is fine-grained, has `Contents: Read-only` on `GPID-WB/pip-sandbox`, and has been authorized if required.
- If you get `404`, confirm the release tag, PPP year, file name, and repository access.

## Security

Keep the token local. Do not commit it to a repository or place it in shared code, email, chat, or screenshots.
