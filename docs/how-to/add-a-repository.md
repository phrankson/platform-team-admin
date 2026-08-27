# How to add a repository

## 1. Add an entry to the config file

Open [`config/platform_team_values.yaml`](../../config/platform_team_values.yaml)
and add a new entry under `github_repositories`:

```yaml
github_repositories:
  # ...existing entries...

  - name: my-new-repo
    description: >
      One or two sentences describing what this repo is for.
    visibility: public
```

`visibility` accepts `public`, `private`, or `internal`, and defaults to
`private` if omitted. See
[Configuration schema](../reference/config-schema.md) for every field this
block supports.

> Branch protection on the Free GitHub plan only applies to public
> repositories. If you set `visibility: private`, the branch protection
> rule this project applies will silently have no effect. See
> [Troubleshooting](troubleshooting.md#branch-protection-doesnt-apply-to-a-private-repo).

## 2. Preview the change

```console
$ pulumi preview
```

Confirm the output shows exactly one repository and one branch protection
rule being created, and nothing else changing:

```
Resources:
    + 2 to create
    14 unchanged
```

## 3. Apply the change

```console
$ pulumi up
```

Confirm the prompt when asked. Pulumi will create the repository, then the
branch protection rule on its `main` branch (branch protection depends on
the repository existing first, so this order is enforced automatically).

## 4. Verify

```console
$ gh repo view <your-org>/my-new-repo
$ gh api repos/<your-org>/my-new-repo/branches/main/protection \
    --jq '{enforce_admins: .enforce_admins.enabled, signed_commits: .required_signatures.enabled}'
```

## Removing a repository

This project sets `protect=True` on every repository resource, which
means `pulumi destroy` — and simply deleting the entry from the config
file — will **not** delete the repository. This is deliberate: repository
deletion is unrecoverable, and this project treats it as something that
requires a manual, explicit action outside of Pulumi. To actually remove a
repository, delete it directly via `gh repo delete <org>/<repo>` or the
GitHub UI, then remove its entry from the config file to keep the config
accurate.
