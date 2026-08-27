# Repos and Governance

Part of the [platform-team-administration learning companion](README.md).
Read the [index](README.md) first for the Department of Buildings and
Planning analogy this builds on.

---

## Issuing the permit: `github.Repository`

A permit isn't a building — it's a record that a parcel exists, belongs to
a specific project, and can now legally have things built on it. That's
exactly what
[`pulumi_repo_create.py`](../pulumi_repo_create.py) does for each entry in
[`config/platform_team_values.yaml`](../config/platform_team_values.yaml):

```yaml
github_repositories:
  - name: platform-core
    description: >
      Core platform runtime: Kubernetes cluster provisioning, network
      configuration, and service mesh setup.
    visibility: public
```

```python
repo = github.Repository(
    repo_name,
    name=repo_name,
    description=repo_description,
    visibility=visibility,
    allow_auto_merge=False,
    delete_branch_on_merge=False,
    opts=ResourceOptions(
        provider=github_provider,
        protect=True,  # prevents accidental deletion via pulumi destroy
    ),
)
```

`protect=True` is the department's equivalent of a permit that can't be
torn up on a whim. Pulumi's whole value proposition rests on "the code is
the source of truth — delete the code's declaration and the real thing
goes with it." That's usually exactly what you want: delete a line
declaring a Kubernetes namespace, and recreating it later costs nothing.
Deleting a *repository* is a different order of consequence — years of
commit history and every issue ever filed, gone, unrecoverable. `protect=True`
is a deliberate exception carved out of Pulumi's normal "code controls
reality completely" rule, for the one resource type where "oops" doesn't
have an undo button.

## Building codes: `github.BranchProtection`

A permit alone doesn't guarantee anything gets built *safely*. That's what
a building code is for — a fixed set of rules applied identically to every
project, regardless of who's building it or how much they trust their own
judgment that day. `github.BranchProtection` is this repo's building code,
applied to `main` on every single repo the moment it's created:

```python
github.BranchProtection(
    f"{repo_name}-main-branch-protection",
    repository_id=repo.node_id,
    pattern="main",
    enforce_admins=True,
    require_signed_commits=True,
    required_pull_request_reviews=[...],
    opts=ResourceOptions(provider=github_provider, depends_on=[repo]),
)
```

`depends_on=[repo]` is worth understanding as a general Pulumi mechanic,
not just a detail of this file: Pulumi doesn't execute your Python
top-to-bottom the way a script does. It builds a graph of what depends on
what, then only creates a resource once everything it depends on already
exists. Here, that guarantees the permit (the repo) exists before the code
inspector (branch protection) shows up — without this line, Pulumi could
try to attach a building code to a parcel that doesn't exist yet.

Two of this code's rules deserve their own explanation, because *why* they
work is more useful than knowing *that* they exist:

**`require_signed_commits=True`.** A regular commit says "this came from
whoever typed this git config" — a plain-text claim, as trustworthy as a
name written on a permit application in pencil. A *signed* commit is
different: the committer has a private key only they possess, and every
commit gets a cryptographic seal only that key could have produced. Anyone
can verify the seal is genuine without ever seeing the private key itself
— the same way a wax seal pressed by a unique signet ring proves who sent
a letter, without the recipient needing to have met the sender. This is
why an auditor asking "prove Alice wrote this" gets a cryptographic answer
instead of "we trust our git config."

**`enforce_admins=True`.** A codes department that exempts its own
director from the building code isn't enforcing a code — it's enforcing a
suggestion with an escape hatch. This is the correct, uncomfortable
default: rules that the person who wrote them can personally bypass aren't
really rules. That correctness collided with reality almost immediately,
on a repo maintained by exactly one person.

<details>
<summary><strong>Predict before reading on:</strong> <code>enforce_admins</code> is on. <code>required_approving_review_count</code> was <code>1</code>. There is exactly one GitHub account on this whole project — the same account that opens every pull request. What happens when that account tries to merge its own change?</summary>

GitHub itself refuses to let an account approve its own pull request — this
isn't a setting anyone chose, it's how the platform works. So the PR needs
one approval to merge, the only human on the project cannot provide it, and
`enforce_admins` means the org owner can't override the block either. The
PR is now permanently stuck — not because anything is broken, but because
two individually-correct rules ("require a review," "don't let admins skip
rules") combine into a deadlock the instant there's only one person.

The fix wasn't to weaken either rule — it was recognizing that the
hardcoded number `1` was silently assuming a team size that didn't exist
yet, and making it a config value instead:

```python
required_approving_review_count: int = data.get("branch_protection", {}).get(
    "required_approving_review_count", 1
)
```

```yaml
# required_approving_review_count: 0 while solo-maintaining with a single
# GitHub account (self-approval isn't allowed and enforce_admins blocks
# bypassing it). Raise back to 1+ once a second reviewer/collaborator exists.
branch_protection:
  required_approving_review_count: 0
```

Sit with what actually changed here: the fix isn't a workaround bolted on
top of the rule — it's making the rule itself *honestly reflect a real
constraint* (team size) that the original hardcoded `1` was quietly
pretending wasn't relevant. This is a genuinely common shape of bug in
governance code: a rule that's correct for the org you'll eventually have,
but silently wrong for the org you actually have today.
</details>

One more real, lower-drama constraint worth knowing: GitHub's **Free plan
cannot apply branch protection to a private repository** — the feature is
Free-tier-only for *public* repos. Every repo in this project is
`visibility: public` for exactly this reason — not a security posture
choice, a plan-tier constraint that quietly shaped a visibility decision
made for entirely different reasons.

**Try it yourself** — this is the live, real building code on a real repo,
matching the config file exactly:

```console
$ gh api repos/phrankson/platform-team-admin/branches/main/protection \
    --jq '{enforce_admins: .enforce_admins.enabled, signed_commits: .required_signatures.enabled, reviews_required: .required_pull_request_reviews.required_approving_review_count}'
{
  "enforce_admins": true,
  "signed_commits": true,
  "reviews_required": 0
}
```

## Governance at scale

Branch protection here is a small example of a pattern that matters a lot
more once an organization gets bigger. At a small enough scale, a team
lead can personally review every pull request and remember every rule that
applies. That stops being possible once there are dozens of teams and
hundreds of repos. Nobody can hold all of that in their head, and nobody
should have to.

Governance at scale means the rules get enforced by the platform itself,
uniformly, regardless of team size, seniority, or how busy someone is that
week. That's exactly what's happening here: the branch protection rule in
`platform_team_values.yaml` gets applied to every repo the moment it's
created, not because a person remembers to set it up each time.

This pattern shows up again later in a more general form. Branch
protection only governs how code gets merged. `platform-services`'s
policy-as-code setup governs what actually gets deployed to a cluster —
rejecting a manifest that uses an unpinned image tag, for example. Same
idea, applied one layer further down the pipeline: a rule written once,
enforced automatically, everywhere it applies.

Continue to [**Hooks and CI/CD**](hooks-and-cicd.md) for the other layer of
enforcement — the one that happens *before* a commit ever reaches GitHub at
all — plus secrets management and the deployment pipeline.
