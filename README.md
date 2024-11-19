
## What?

A set of scripts to be sourced to ease
- building local environments
- starting SDCs on local and cloud environemnts
- running STF tests on local and cloud environments

All the scripts start with `env.` and all define an environment variable `$HELP`.

## Requirements

The scripts obtain some secrets and configuration using the 1password cli
to get the items of type login from the "Employee" vault. They rely on
two aliases to activate the proper STF virtual envs:
- `py-4.x-stf` (for me, set to `$HOME/py-envs/4.x-stf/bin/activate`)
- `py-3.x-stf` (for me, set to `$HOME/py-envs/3.x-stf/bin/activate`)

They expect repos on `~/src/streamsets`.

External dependencies:
- [HTTPie](https://httpie.io)
- [jq](https://jqlang.github.io/jq/)
- [op](https://developer.1password.com/docs/cli/get-started/#install) - 1password cli
- [Rancher Desktop](https://rancherdesktop.io) using docker
- [yq](https://github.com/mikefarah/yq?tab=readme-ov-file#macos--linux-via-homebrew)

## Scripts

### `env.local.platform.zsh`

Local build of platform, using `dpm-scripts/platform.py`.  
<http://host.docker.internal:4200>  
By default, uses SDC 5.12.0.

Requires this 1password item configuartion:
- `local.platform`:
    - `username`
    - `password`
    - `firebase-api-key`

### `env.dev.my-org.zsh`

Start SDCs and launch STF tests on a cloud platform instance.  
Can be copied and adapted for other organizations/instances,
as it is a simple script that sources `_env.platform.zsh`.  
By default, uses SDC 5.11.0.

Requires this 1password item configuartion:
- `platform.dev.my-org`:
    - `username`
    - `password`
    - `website` 
    - `firebase-api-key`
    - `CRED_ID`
    - `CRED_TOKEN`

### `env.local.3x.zsh`

Local build of a maven-based version of 3.x, using `dpm-scripts/dom-util.py`.  
It uses postgres to ease running at the same time than the local platform build.  
By default, uses SDC 5.8.0.  
<http://host.docker.internal:20631>

Requires this 1password item configuartion:
- `local.3x`
    - `username`
    - `password`

### `env.cloud.dpmsupport.zsh`

Start SDCs and launch STF tests on the 3.x cloud instance.  
Can be copied and adapted for other organizations/instances,
as it is a simple script that sources `_env.cloud.3x.zsh`.  
By default, uses SDC 5.10.0.

Note that STF tests are unlikely to work, as `dpm-tests`
makes lots of assumptions based on clustedock that won't
hold true for a real cloud instance.

Requires this 1password item configuartion:
- `cloud.dpmsupport`
    - `username`
    - `password`
    - `website`
    - `new_user_email` (used if your STF test attempts to create a user)


### `env.genesis.dpmsupport.zsh`

Start SDCs and launch STF tests on the 3.x genesis cloud instance.  
Can be copied and adapted for other organizations/instances,
as it is a simple script that sources `_env.cloud.3x.zsh`.  
By default, uses SDC 5.9.1.

Note that STF tests are unlikely to work, as `dpm-tests`
makes lots of assumptions based on clustedock that won't
hold true for a real cloud instance.

Requires this 1password item configuartion:
- `genesis.dpmsupport`
    - `username`
    - `password`
    - `website`
    - `new_user_email` (used if your STF test attempts to create a user)
