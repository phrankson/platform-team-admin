# How to manage secrets

This project keeps secret values in two places, for two different reasons:

- **Pulumi's own encrypted stack config** (`pulumi config set --secret`) is
  what Pulumi actually reads at runtime. This is the live source of truth.
- **Bitwarden** is the durable, auditable record of the same values —
  where they're stored, versioned, and recoverable independent of Pulumi
  Cloud.

Adding or rotating a secret means updating both. Updating only Bitwarden
has no effect on what Pulumi actually uses; updating only Pulumi config
leaves Bitwarden's record stale.

## Add a new secret definition to Bitwarden

1. Create a new JSON file in [`secrets-setup/`](../../secrets-setup/),
   following the shape of the existing `*_example` files:

   ```json
   {
     "type": 1,
     "name": "My New Secret",
     "notes": "What this secret is for",
     "fields": [
       {"name": "field-name", "value": "the-actual-value", "type": 0}
     ],
     "login": {"uris": [], "username": null, "password": null, "totp": null, "passwordRevisionDate": null}
   }
   ```

   The `name` field is what the load script matches on — it must be exact.

2. Run the load script:

   ```console
   $ cd secrets-setup
   $ ./load_secrets.sh
   ```

   The script authenticates to Bitwarden, then for every `*.json` file in
   the directory, checks for an item with that **exact** name. If found,
   it updates it; otherwise it creates a new item. This is safe to re-run.

## Update an existing secret's value

Edit the `value` field in the corresponding JSON file, then re-run
`./load_secrets.sh` from `secrets-setup/`. Because the script matches on
exact name, it will update the existing Bitwarden item rather than
creating a duplicate.

## Rotate the GitHub token Pulumi actually uses

1. Generate a new GitHub personal access token (or app installation
   token) with the same permissions as the current one.
2. Update `secrets-setup/github_secrets.json`'s `pulumi-github-token`
   field with the new value, and run `./load_secrets.sh` to update
   Bitwarden's record.
3. Update Pulumi's own config, which is what's actually used at runtime:

   ```console
   $ pulumi config set github:token <new-token-value> --secret
   ```

4. Revoke the old token in GitHub's settings once you've confirmed
   `pulumi preview` still works with the new one.

## Invalidate a secret entirely

If a secret is compromised or no longer needed:

1. Revoke it at the source (revoke the GitHub token in GitHub's settings,
   for example) — this is what actually stops it from working, regardless
   of what's stored anywhere else.
2. Delete or update the corresponding Bitwarden item so the vault doesn't
   keep a record of a value that no longer works.
3. If it was set in Pulumi config, remove it: `pulumi config rm
   github:token`.

Revoking at the source first means the secret stops working immediately,
even if you haven't finished cleaning up its records elsewhere yet.
