# Troubleshooting

Real problems this project has hit, and how to resolve them.

## Bitwarden overwrote the wrong item

**Symptom:** after running `load_secrets.sh`, an existing Bitwarden item's
contents changed unexpectedly, even though its name didn't match any file
you loaded.

**Cause:** `bw get item <name>` performs fuzzy/word matching, not an
exact-name lookup. If you (or an older version of a script) used it to
check whether an item exists, a name like "Pulumi Secrets" can match an
unrelated existing item like "GitHub Secrets."

**Fix:** confirm [`secrets-setup/load_secrets.sh`](../../secrets-setup/load_secrets.sh)
is using the exact-match lookup, not `bw get item`:

```bash
existing_item=$(bw list items --search "$item_name" --session "$BW_SESSION" 2>/dev/null \
    | jq --arg n "$item_name" '[.[] | select(.name == $n)] | first // empty')
```

If a secret was overwritten, restore it from its local `*.json` source
file by re-running the script, or from Bitwarden's built-in item history
if the source file no longer has the original value.

## A pull request can't be merged — stuck on required review

**Symptom:** a PR shows "Review required" and the account that opened it
cannot approve its own PR, and `enforce_admins` prevents the org owner
from bypassing the check.

**Cause:** `required_approving_review_count` is set higher than the
number of people who can actually review — most commonly, set to `1` on
a repo with exactly one contributor.

**Fix:** lower `required_approving_review_count` in the
`branch_protection` section of
[`config/platform_team_values.yaml`](../../config/platform_team_values.yaml)
to match your actual team size, then `pulumi up`:

```yaml
branch_protection:
  required_approving_review_count: 0
```

Raise it back to `1` or more once a second reviewer exists. Do not disable
`enforce_admins` to work around this — that removes the guarantee branch
protection exists to provide.

## Branch protection doesn't apply to a private repo

**Symptom:** `pulumi up` reports success, but `gh api
repos/<org>/<repo>/branches/main/protection` returns a 404, or the
protection settings don't match what's declared.

**Cause:** GitHub's Free plan only supports branch protection on **public**
repositories. A repo declared with `visibility: private` on the Free plan
will not actually get the protection rule applied, even though Pulumi
reports the resource as created.

**Fix:** either upgrade to a paid GitHub plan that supports private-repo
branch protection, or set `visibility: public` in the repo's config entry.
This project uses `public` for every repository for this reason.

## `pulumi preview` shows unexpected changes to an existing repository

**Symptom:** a repo that hasn't been touched in the config file shows up
in `pulumi preview` as having drifted.

**Cause:** most commonly, someone changed a setting directly in GitHub's
UI (description, visibility) that Pulumi also manages. Pulumi's next
`preview`/`up` will show this as drift and, on `up`, revert it back to
match the config file — the config file is the source of truth, not
whatever's currently set in GitHub's UI.

**Fix:** if the manual change was intentional, update the config file to
match it instead of letting Pulumi revert it. If it wasn't intentional,
let `pulumi up` proceed — it will correct it.
