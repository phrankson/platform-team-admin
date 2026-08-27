# How to add a team member

## 1. Uncomment or add an entry

[`config/platform_team_values.yaml`](../../config/platform_team_values.yaml)
has a `github_organization_members` section, commented out by default
since it's unused on a solo-maintained project. Uncomment it and add an
entry:

```yaml
github_organization_members:
  - name: Jane Doe
    github-role: member
    github-username: janedoe
    email: jane.doe@company.com
```

`github-role` accepts `admin` or `member`. `name` and `email` are
informational only and aren't sent to GitHub's API — `github-username` is
the field that actually matters.

The person being added must already have a GitHub account; this project
can't create one for them.

## 2. Preview and apply

```console
$ pulumi preview
$ pulumi up
```

## 3. Verify

```console
$ gh api orgs/<your-org>/members/<github-username>
```

A `204` response (no content) confirms membership. A `404` means the
invitation is still pending — GitHub requires the invited user to accept
before they show up as a full member.

## What this can't do

The organization **owner** account can't be managed this way — GitHub's
API doesn't support automating ownership transfer or owner-level changes
through this mechanism. If you need to test onboarding flows, use a
second, non-owner account.
