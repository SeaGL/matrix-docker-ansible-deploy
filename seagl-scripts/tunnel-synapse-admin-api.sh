#!/usr/bin/env bash
# Exposes the Synapse admin API locally, as an alternative to enabling
# `matrix_synapse_container_labels_public_client_synapse_admin_api_enabled`.
set -Eeuo pipefail

detect_remote() {
  echo 'Looking up internal address of Synapse container' >&2
  ip="$(
    ANSIBLE_LOAD_CALLBACK_PLUGINS='1' ANSIBLE_STDOUT_CALLBACK='json' \
    ansible \
      --inventory 'inventory/' \
      'ephemeral' \
      --module-name 'ansible.builtin.shell' \
      --args "sudo docker inspect --format '{% raw %}{{ json .NetworkSettings.Networks }}{% endraw %}' matrix-synapse" \
    | jq --raw-output '.plays[0].tasks[0].hosts.ephemeral.stdout' \
    | jq --raw-output '.["matrix-homeserver"].IPAddress'
  )"

  echo "$ip:8008"
}

detect_ssh_destination() {
  echo 'Looking up SSH parameters of Ansible host' >&2
  json="$(ansible-inventory --inventory 'inventory/' --host 'ephemeral')"
  host="$(<<<"$json" jq --raw-output '.ansible_host')"
  user="$(<<<"$json" jq --raw-output '.ansible_ssh_user // empty')"

  echo "${user:+"$user@"}$host"
}

local="127.0.0.1:${PORT:-8008}"
remote="$(detect_remote)"
ssh_destination="${SSH_DESTINATION:-$(detect_ssh_destination)}"

echo "Exposing Synapse admin API via $ssh_destination at http://$local/_synapse/admin" >&2
exec ssh -N -L "$local:$remote" "$ssh_destination"
