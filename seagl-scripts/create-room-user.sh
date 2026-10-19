#!/usr/bin/env bash
set -Eeuo pipefail

api_access_token="$MATRIX_ACCESS_TOKEN"
api_origin="${API_ORIGIN:-http://127.0.0.1:8008}"
user_avatar='mxc://seattlematrix.org/VMXxAOmOegYTuAfKUxtkksUl'
user_id="$1"
user_display_name="$2"
user_password="${PASSWORD:-}"

if [[ -z "$user_password" ]]; then
  user_password="$(xkcdpass)"
  echo "Generated password for $user_id: $user_password"
fi

echo "Creating $user_id with name “$user_display_name” and ${#user_password}-character password" >&2
http --check-status put "$api_origin/_synapse/admin/v2/users/$user_id" \
  Authorization:"Bearer $api_access_token" \
  avatar_url="$user_avatar" \
  password="$user_password" \
  displayname="$user_display_name" \
