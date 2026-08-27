# Architecture and design choices

This document explains the reasoning behind decisions in this codebase,
for anyone maintaining or extending it. It assumes general engineering
background, not prior context on this specific project.

## Why declarative config plus Pulumi, not a script with arguments

Every repository, branch protection rule, and org member this project
manages is declared in
[`config/platform_team_values.yaml`](../../config/platform_team_values.yaml)
rather than created by running a script with flags. This buys three
specific properties a script-with-arguments approach doesn't:

- **Review before execution.** A pull request against the config file
  shows the exact diff of what will change before it changes, using
  ordinary code review.
- **Drift detection.** `pulumi preview` can answer "does reality match
  what's declared?" at any time. A script has no equivalent — there's no
  record of what should be true to compare against.
- **No per-invocation memory required.** Every setting a repository needs
  is a line in a file, not a set of flags someone has to remember to pass
  correctly, the same way, every time.

Pulumi specifically (over Terraform or a hand-rolled script using the
GitHub API directly) was chosen for its typed Python SDK
(`pulumi-github`) and its dependency-graph model, which lets branch
protection declare `depends_on=[repo]` and have Pulumi guarantee the
repository exists first, without manual ordering logic.

## Why `protect=True` on repositories but not other resources

Most Pulumi resources in this project can be freely destroyed and
recreated with no real cost — a branch protection rule, an org membership.
Repositories are the exception: deleting one is unrecoverable and destroys
issue history, PR history, and anything else attached to it. `protect=True`
is a deliberate, narrow exception to the normal "code fully controls
reality" model, applied only where "oops" has no undo.

## Two layers of enforcement

This project enforces commit conventions at two different layers, and
deliberately does not rely on just one:

- **`.git-hooks/commit-msg`**, installed locally via
  `scripts/install-githooks.sh`, runs on the contributor's own machine,
  before a commit is even made. Fast, but bypassable with `git commit
  --no-verify`, and only present if a contributor ran the install step.
- **`github.BranchProtection`**, applied server-side to every repository,
  cannot be bypassed by a missing local hook or a `--no-verify` flag. This
  is the layer that actually guarantees the rule holds.

The local hook exists for fast feedback during normal work, not as the
actual enforcement mechanism. If a rule matters, it has to be enforced
server-side; a local hook alone is a convenience, not a guarantee.

## Why `enforce_admins` is unconditional but review count is configurable

`enforce_admins: true` is hardcoded — there's no config option to disable
it. A rule the org owner can personally bypass isn't a rule.

`required_approving_review_count`, by contrast, is read from config with a
default of `1`:

```python
required_approving_review_count: int = data.get("branch_protection", {}).get(
    "required_approving_review_count", 1
)
```

This distinction exists because of a real deadlock this project hit: with
`enforce_admins` on and review count at `1`, a solo-maintained repo can't
merge anything — GitHub disallows self-approval, and `enforce_admins`
blocks the owner from overriding the block. The fix wasn't to weaken
`enforce_admins`; it was recognizing that a fixed review count of `1`
silently assumed a team size the project didn't have yet, and exposing it
as config instead. See
[Troubleshooting](../how-to/troubleshooting.md#a-pull-request-cant-be-merged--stuck-on-required-review)
for the operational fix.

## Why GitHub token values live in Bitwarden, not just Pulumi config

Pulumi's encrypted stack config is sufficient for Pulumi to function, but
it's tied to one backend (Pulumi Cloud) with no independent audit trail or
recovery path if that backend account is lost. Bitwarden holds the same
values as a separate, durable, auditable record — see
[Manage secrets](../how-to/manage-secrets.md) for the operational
distinction between the two.

## Why push previews, only a tag deploys

[`.circleci/config.yml`](../../.circleci/config.yml) applies changes only
on a version tag, after a manual approval — never on a plain push to
`main`, even though `main` is also the branch protected by required
reviews. This is deliberate: code review (the PR merge) and infrastructure
apply (`pulumi up`) are different actions with different blast radii, and
this project doesn't assume a reviewed merge is automatically safe to
apply immediately. Tagging is a second, explicit signal — "this specific
commit is ready to apply" — separate from "this commit was reviewed and
merged."
