#!/usr/bin/env bash
set -euo pipefail

# Load Bitwarden credentials from ../.env
set -o allexport
source "$(dirname "$0")/../.env"
set +o allexport

# Log in (no-op if already logged in) and unlock the vault
bw login --apikey || true
BW_SESSION=$(bw unlock --passwordenv BW_PASSWORD --raw)

cd "$(dirname "$0")"

for json_file in *.json; do
    echo "Processing: $json_file"
    item_name=$(cat "$json_file" | jq -r .name)
    existing_item=$(bw get item "$item_name" --session "$BW_SESSION" 2>/dev/null)
    if [ -n "$existing_item" ]; then
        echo "Item '$item_name' exists, updating..."
        item_id=$(echo "$existing_item" | jq -r .id)
        cat "$json_file" | bw encode | bw edit item "$item_id" --session "$BW_SESSION"
    else
        echo "Item '$item_name' does not exist, creating..."
        cat "$json_file" | bw encode | bw create item --session "$BW_SESSION"
    fi
done

bw sync --session "$BW_SESSION"
bw lock
