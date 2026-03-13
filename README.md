# pipsb

`pipsb` loads test `.dta` files from a private GitHub repository directly into Stata memory.

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
2. Repository access: only the private data repository, or all repositories if needed
3. Repository permissions: `Contents = Read-only`
4. Expiration: a reasonable period such as 90 or 180 days

If your organization requires it, complete SSO authorization or admin approval.

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

## Example

```stata
pipsb, filename(syears)
```

## Troubleshooting

- If the token is not found, check `profile.do` and restart Stata.
- If you get `401` or `403`, confirm the token is fine-grained, has `Contents: Read-only`, and has been authorized if required.
- If you get `404`, confirm the file path, branch, and repository access.

## Security

Keep the token local. Do not commit it to a repository or place it in shared code, email, chat, or screenshots.
