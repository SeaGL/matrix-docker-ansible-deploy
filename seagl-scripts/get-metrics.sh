#!/bin/sh

set -euo pipefail

elimination_set="('@aj-test2:$(date +%Y).seagl.org', '@test-1:$(date +%Y).seagl.org')"

function prompt_continue() {
	read -n 1 -s -r -p 'Press any key to continue... '
	printf '\n'
}

function remote_psql() {
	ssh -t $(date +%Y)-ephemeral.host.seagl.org sudo docker exec -it matrix-postgres psql ${2-} -c \""$1"\" synapse
}

echo You will need to review the users database to make sure we\'re eliminating all staff/test users.
prompt_continue

eliminators="name NOT SIMILAR TO '@room-[[:digit:]]+:$(date +%Y).seagl.org' AND admin = 0 AND name NOT IN $elimination_set"
remote_psql "SELECT name, admin, user_type, deactivated, approved, locked, suspended FROM users WHERE $eliminators;"

echo 'If there are staff users still present in the listing, ^C to abort this script, edit it, and then try again.'
prompt_continue

printf 'Number of non-staff/test accounts registered on ephemeral homeserver: '
remote_psql "SELECT COUNT("'*'") FROM users WHERE $eliminators;" -t | tr -d ' '
