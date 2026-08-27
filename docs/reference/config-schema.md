# Configuration schema

Full field reference for
[`config/platform_team_values.yaml`](../../config/platform_team_values.yaml),
the single source of truth read by
[`pulumi_repo_create.py`](../../pulumi_repo_create.py).

## `github_repositories`

A list of repositories to create and manage.

| Field | Type | Required | Default | Effect |
|---|---|---|---|---|
| `name` | string | Yes | — | Repository name. Use kebab-case. Also used as the Pulumi resource name. |
| `description` | string | No | `""` | Shown on the repository's GitHub page. |
| `visibility` | string | No | `private` | One of `public`, `private`, `internal`. Note: branch protection requires `public` on GitHub's Free plan — see [Troubleshooting](../how-to/troubleshooting.md#branch-protection-doesnt-apply-to-a-private-repo). |

Every repository created from this list also gets:

- `allow_auto_merge: false`
- `delete_branch_on_merge: false`
- `protect=True` (Pulumi resource option — `pulumi destroy` will not
  delete the repository; see
  [Add a repository](../how-to/add-a-repository.md#removing-a-repository))

## `branch_protection`

Applies identically to the `main` branch of every repository declared
above.

| Field | Type | Required | Default | Effect |
|---|---|---|---|---|
| `required_approving_review_count` | integer | No | `1` | Minimum approvals required before a PR can merge. |

Every repository also gets, unconditionally (not configurable):

- `enforce_admins: true` — the rule applies even to the organization owner.
- `require_signed_commits: true` — every commit on `main` must be
  GPG- or SSH-signed.
- `dismiss_stale_reviews: true` — a new commit invalidates prior approvals.

## `github_organization_members`

A list of members to add or update in the GitHub organization. Commented
out by default.

| Field | Type | Required | Default | Effect |
|---|---|---|---|---|
| `name` | string | No | — | Informational only. Not sent to GitHub's API. |
| `github-role` | string | Yes | — | One of `admin`, `member`. |
| `github-username` | string | Yes | — | Must already have a GitHub account. |
| `email` | string | No | — | Informational/audit only. Not used by the API. |

The organization owner account cannot be managed through this mechanism.
