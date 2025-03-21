# README

## Purpose

This container has a few tools installed so that a user may execute those tools locally from any environment.

The original purpose was to create a locally accessible container that can use the current user's credentials as previously setup in order to execute various tasks.

Most notable among these tasks (for IB) are packer builds and ansible playbook runs.  Having some additional capabilities in place to mount AWS and Docker Hub credentials facilitates this. 

There exists a script in `scripts/runbox.sh` that will attempt to mount:

1. If the value `IBVOLUME` is set, it will attempt to mount that as `/root`
2. If `IBVOLUME` is not available, it will create a volume called `${USER}-vol` and attempt to mount that as `/root`.
3. If `NOIBVOLMOUNT` is set to `true`, then no volume will be mounted as `/root`.
4. The `.envrc` file from the local `${PWD}` as the `/root/.envrc` 
5. If that is not available, it will attempt to do the same for `${HOME}/.envrc`
6. If the value of `NOENVMOUNT` is set to `true`, then neither envrc mounting will occur.
7. It will attempt to mount `${PWD}/.aws` as `/root/.aws` (allowing some flexibility in container AWS config).
8. If step 4 did not exist, then it will look for `${HOME}/.aws`
9. If the value of `NOAWSMOUNT` is set to `true`, then nothing will be mounted as `/root/.aws`

There exists a Github action to deploy the container to Docker Hub upon a successful build.

## Contents

The base is from Fedora 41

The tools that are explicitly included are:

- direnv
- git
- python39-devel
- findutils
- environment-modules
- dnf-plugins-core
- sudo (to keep shells from going wonky if it's not present)
- pipx
- poetry
- ansible
- awscliv2
- tfenv and a version of terraform set to TFVERSION
- packer set to PACKERVERSION (defaults to latest)
- goofys to mount s3 buckets with FUSE
- opentofu's `tofu`

## Modification

You could, of course, modify any of the files to make changes.  This is especially true of the `Dockerfile`.

The GHA in `.github/workflows/docker-hub.yml` was copied from Docker Hub's documentation and modified slightly.  No one will be mad if you want to modify it further.
