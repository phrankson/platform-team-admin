# CLI and scripts reference

## Pulumi commands

| Command | Effect |
|---|---|
| `pulumi stack select dev` | Select the (only) stack this project uses. |
| `pulumi config set github:owner <org>` | Set the GitHub organization to manage. |
| `pulumi config set github:token <token> --secret` | Set the GitHub token, encrypted at rest. |
| `pulumi config` | List current stack config (secret values masked). |
| `pulumi config rm <key>` | Remove a config key. |
| `pulumi preview` | Show what would change, without applying anything. |
| `pulumi up` | Apply changes. Prompts for confirmation unless `--yes` is passed. |
| `pulumi destroy` | Tear down managed resources. Repositories with `protect=True` will not actually be deleted. |

## `secrets-setup/load_secrets.sh`

Loads every `*.json` file in `secrets-setup/` into Bitwarden as a
create-or-update operation, matched by exact item name.

**Usage:**

```console
$ cd secrets-setup
$ ./load_secrets.sh
```

**Requires**, read from `../.env`:

| Variable | Purpose |
|---|---|
| `BW_CLIENTID` | Bitwarden API key client ID |
| `BW_CLIENTSECRET` | Bitwarden API key client secret |
| `BW_PASSWORD` | Bitwarden master password, used to unlock the vault |

**Behavior:**

- Authenticates via `bw login --apikey` if not already logged in.
- Unlocks the vault with `BW_PASSWORD`, capturing a session token.
- For each `*.json` file: looks up an item with an **exact** name match
  (not `bw get item`'s fuzzy match); updates it if found, creates it
  otherwise.
- Syncs the vault and locks it when finished, regardless of outcome.

**Exit behavior:** the script uses `set -euo pipefail` and exits
non-zero on missing environment variables or a failed vault unlock. A
failure to create or update any individual secret is reported per-item
but does not stop processing of the remaining files.

## `scripts/install-githooks.sh`

Copies `.git-hooks/commit-msg` into `.git/hooks/commit-msg` for the local
clone.

**Usage:**

```console
$ ./scripts/install-githooks.sh
```

**Requires:** must be run from inside a git repository (uses `git
rev-parse --show-toplevel` to locate the repo root). Fails with a
non-zero exit code if not run inside a git repo, or if
`.git-hooks/commit-msg` doesn't exist.

**Idempotent:** safe to re-run; it overwrites any existing installed hook.
