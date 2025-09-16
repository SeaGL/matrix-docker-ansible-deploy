# Ephemeral Matrix server setup

This is a "fork" of [spantaleev/matrix-docker-ansible-deploy](https://github.com/spantaleev/matrix-docker-ansible-deploy). I say "fork" and not fork because really all this is doing is version-controlling our configuration.

## To set up an ephemeral homeserver

1. Instantiate the [`ephemeral_homeserver` Terraform module](https://github.com/SeaGL/seagl-terraform/tree/8c8ae33c26c070b4d8fa29f099bd5bada79f84bd/ephemeral_homeserver) for this year
2. Add the new instance's SSH key to [this GitHub Actions variable](https://github.com/SeaGL/seagl-ansible/settings/variables/actions/SSH_KNOWN_HOSTS) and [this second variable](https://github.com/SeaGL/matrix-docker-ansible-deploy/settings/variables/actions/SSH_KNOWN_HOSTS)
3. Add the new instance to Ansible's inventory. Make sure the inventory group is called `ephemeral`.
4. Push the inventory update, in order to run the regular Ansible playbooks against it (you need GitHub Actions to bootstrap everyone else into the instance)
5. Update this repo (see below)
6. Push this repository. GitHub Actions will configure the homeserver automatically.
7. If the GitHub Actions run fails, rerun it. This is necessary on initial setup due to ordering/timing issues.
8. Run the homeserver through [Matrix Federation Tester](https://federationtester.matrix.org/), just to be sure.

## To run locally

You shouldn't need to do this.

1. Run `ansible-galaxy install -r requirements.yml -p roles/galaxy/ --force`
2. `ansible-playbook --ask-vault-pass -i inventory/ --tags=install-all,ensure-matrix-users-created,start setup.yml`

You will be prompted for the vault password, which is in Vaultwarden.

## Updating this repo

TODO (tl;dr just read upstream's changelog, then `git merge`)
