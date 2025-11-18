#!/bin/bash

set -euo pipefail

elimination_set="('@aj-test2:$(date +%Y).seagl.org', '@test-1:$(date +%Y).seagl.org', '@polygonart6667:$(date +%Y).seagl.org')"

function prompt_continue() {
	read -n 1 -s -r -p 'Press any key to continue... '
	printf '\n'
}

function remote_psql() {
	# LogLevel suppresses disconnection messages - https://superuser.com/a/1172143/121259
	# See also https://serverfault.com/a/981481/167999 for pager=off
	ssh -o LogLevel=QUIET -t $(date +%Y)-ephemeral.host.seagl.org sudo docker exec -it matrix-postgres psql -P pager=off ${2-} -c \""$1"\" synapse
}

echo You will need to review the users database to make sure we\'re eliminating all staff/test users.
prompt_continue

with_nonstaff_clause="WITH non_staff_users AS (SELECT "'*'" FROM users WHERE name NOT SIMILAR TO '@room-[[:digit:]]+:$(date +%Y).seagl.org' AND admin = 0 AND name NOT IN $elimination_set)"
remote_psql "$with_nonstaff_clause SELECT name, admin, user_type, deactivated, approved, locked, suspended FROM non_staff_users;"

echo 'If there are staff users still present in the listing, ^C to abort this script, edit it, and then try again.'
prompt_continue

printf 'Number of non-staff/test accounts registered on ephemeral homeserver: '
remote_psql "$with_nonstaff_clause SELECT COUNT("'*'") FROM non_staff_users;" -t | tr -d ' '

echo 'Ephemeral homeserver device registrations, excluding staff:'
echo '(suppressed due to suspected attend portal bugginess - device names did not correspond to UAs)'
echo
#remote_psql "$with_nonstaff_clause SELECT display_name AS \\\"Device display name\\\", COUNT(display_name) AS \\\"Registered devices\\\" FROM devices INNER JOIN non_staff_users ON non_staff_users.name = devices.user_id WHERE display_name != 'master signing key' AND display_name != 'self_signing signing key' AND display_name != 'user_signing signing key' GROUP BY display_name;"

echo 'Ephemeral homeserver device registration count, excluding staff:'
remote_psql "$with_nonstaff_clause SELECT count AS \\\"Number of devices registered\\\", COUNT(count) AS \\\"Users in population\\\" FROM (SELECT user_id, COUNT(user_id) FROM devices INNER JOIN non_staff_users ON non_staff_users.name = devices.user_id WHERE display_name != 'master signing key' AND display_name != 'self_signing signing key' AND display_name != 'user_signing signing key' GROUP BY user_id) GROUP BY count;"

remote_psql "$with_nonstaff_clause SELECT user_agent FROM devices INNER JOIN non_staff_users ON non_staff_users.name = devices.user_id WHERE display_name != 'master signing key' AND display_name != 'self_signing signing key' AND display_name != 'user_signing signing key';" -t | grep -Ev '\([[:digit:]]+ rows\)' | node $(dirname $BASH_SOURCE)/process-uas.js | sort | uniq -c | sort -rh | sed 's/^[[:space:]]*//' | column -t -s' ' --table-columns-limit 2 -o ' | '
