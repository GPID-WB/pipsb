# pipsb




# Private GitHub Token Setup for `pipsb`



## Private Data Access Setup

This project loads data from a private GitHub repository. To use it, each team member must create their own GitHub token, store it locally in Stata, and keep it out of any shared code or repository.

### 1. Create a GitHub token

Create the token from your own GitHub account, not from the organization admin settings.

Go to:

1. Profile photo
2. Settings
3. Developer settings
4. Personal access tokens
5. Fine-grained tokens
6. Generate new token

Use these settings:

1. Token type: Fine-grained personal access token
2. Token name: something descriptive, such as `pipsandbox-private-data-read`
3. Expiration: choose a reasonable period, such as 90 or 180 days
4. Repository access: Only select repositories
5. Selected repository: the private data repository only
6. Repository permissions: Contents = Read-only

After creating the token, copy it immediately. GitHub only shows it once.

### 2. Organization approval or SSO

Depending on your organization settings, the token may also need one of these extra steps:

1. SSO authorization for the organization
2. Admin approval for fine-grained tokens

If the token is created correctly but access still fails, this is one of the first things to check.

### 3. Store the token in Stata

Add the token to your personal Stata startup file so it is loaded automatically each time Stata opens.

Add this line to your local `profile.do`:

```stata
global GPID_GITHUB_TOKEN "your_token_here"
```

Replace `your_token_here` with your real token.

Do not store this token in:

1. A GitHub repository
2. A shared `.do` file
3. Email, chat, or documentation screenshots

### 4. Restart Stata

After saving `profile.do`, restart Stata so the global macro is loaded.

To verify that Stata can see the token, run:

```stata
display "$GPID_GITHUB_TOKEN"
```

If a token-like string appears, the setup worked.

### 5. Test the command

Run a simple test:

```stata
pipsandbox, filename(syears)
```

If everything is configured correctly, the command should download the dataset from the private repository and load it into memory.

### 6. Troubleshooting

If you see a message saying the token is not set:

1. Confirm the line was added to your personal `profile.do`
2. Restart Stata
3. Check with `display "$GPID_GITHUB_TOKEN"`

If you get authentication errors such as 401 or 403:

1. Confirm the token is fine-grained
2. Confirm the token has `Contents: Read-only`
3. Confirm the correct private repository was selected
4. Confirm SSO authorization or admin approval was completed if required

If you get a 404 error:

1. Confirm the file exists in the private repository
2. Confirm the token can access that repository
3. Confirm the repository, branch, and file path are correct

## Short Team Version

### Private GitHub access for pipsandbox

Each user must create their own fine-grained GitHub personal access token from their personal GitHub settings.

Create the token here:

1. Profile photo
2. Settings
3. Developer settings
4. Personal access tokens
5. Fine-grained tokens
6. Generate new token

Recommended token settings:

1. Repository access: Only select repositories
2. Selected repository: the private data repo only
3. Repository permissions: Contents = Read-only

After creating the token, add it to your personal `profile.do`:

```stata
global GPID_GITHUB_TOKEN "your_token_here"
```

Then restart Stata and test:

```stata
display "$GPID_GITHUB_TOKEN"
pipsandbox, filename(syears)
```

Notes:

1. The token is created from your personal GitHub account, not the organization admin page.
2. The organization may still require SSO authorization or admin approval.
3. Never commit the token to a repository or place it in shared code.
