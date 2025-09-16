# Ephemeral Matrix server setup

This is a "fork" of [spantaleev/matrix-docker-ansible-deploy](https://github.com/spantaleev/matrix-docker-ansible-deploy). I say "fork" and not fork because really all this is doing is version-controlling our configuration.

## To set up an ephemeral homeserver

1. Update this repo
2. Make sure that the [`ephemeral_homeserver` Terraform module](https://github.com/SeaGL/seagl-terraform/tree/8c8ae33c26c070b4d8fa29f099bd5bada79f84bd/ephemeral_homeserver) is instantiated for this year, and that you've run the regular Ansible playbooks against it.
3. Run `ansible-galaxy install -r requirements.yml -p roles/galaxy/ --force`
4. `ansible-playbook --ask-vault-pass -i inventory/ --tags=install-all,ensure-matrix-users-created,start setup.yml`

## Updating this repo

TODO (tl;dr just read upstream's changelog, then `git merge`)
