#!/usr/bin/env bash

set -eo pipefail

SERVER=${SERVER:-owo.cafe}

if [[ -z "$ACCESS_TOKEN" ]]; then
  echo "ACCESS_TOKEN is unset, exiting"
  exit 1
fi

authorization=("-H" "Authorization: Bearer $ACCESS_TOKEN")

ids=$(curl -sS "${authorization[@]}" "https://$SERVER/api/v1/admin/reports" |
  jq -r '.[] | select(.action_taken == false) | .target_account.id')

if [[ -z "$ids" ]]; then
  echo "No open reports found."
  exit 0
fi

echo -ne "Will suspend the following accounts:\n$ids\nContinue? (^C to cancel)"
read -r _

echo "$ids" | while read -r id; do
  curl "${authorization[@]}" "https://$SERVER/api/v1/admin/accounts/$id/action" -d 'type=suspend&text=batch-suspend.sh'
  echo "Suspended $id"
done
