#!/bin/echo Run: source

source _env.check-docker.zsh || return 1

if [ -z "$ONE_PASSWORD_ITEM" ]; then
  echo 'The environment variable ONE_PASSWORD_ITEM needs to be set, and needs to specify a 1password item in the Employee vault.'
  echo 'The item needs to specify  `username`, `password`, `website`, and `new_user_email`'
  return 1
fi

name=${1:-$ONE_PASSWORD_ITEM}
echo $name
source set-prompt-for-env.zsh $name 

export DPM_URL=$(op read "op://Employee/$ONE_PASSWORD_ITEM/website")
export DPM_USER=$(op read "op://Employee/$ONE_PASSWORD_ITEM/username")
export DPM_PASSWORD=$(op read "op://Employee/$ONE_PASSWORD_ITEM/password")
# When a new user is created by STF, to what address will the invite go?
export DPM_NEW_USER_EMAIL=$(op read "op://Employee/$ONE_PASSWORD_ITEM/new_user_email")
export SDC_VERSION=5.9.1
export SDC_START_EXTRA_PARAMS="--stage-lib orchestrator jdbc"

export DPM_CMD_SAMPLE_STF='stf \
  -v \
  --env-var DPM_USER \
  --env-var DPM_PASSWORD \
  --env-var DPM_NEW_USER_EMAIL \
  --docker-extra-options="-p 5678:5678/tcp" \
test \
  -v -ra --capture=no \
  --sch-server-url $DPM_URL \
  --sch-username $DPM_USER --sch-password $DPM_PASSWORD \
  --sch-authoring-sdc $SCH_AUTHORING_SDC \
jobs/test_jobs.py::test_simple_job_lifecycle'

export DPM_CMD_START_SDC='stf \
  --env-var HOST_HOSTNAME=host.docker.internal \
start sdc \
  --enable-base-http-url private \
  --https \
  --version $SDC_VERSION \
  --sch-server-url $DPM_URL \
  --sch-username $DPM_USER --sch-password $DPM_PASSWORD \
  --sch-executor-sdc-label $USER \
  $(echo $SDC_START_EXTRA_PARAMS)'
# This last echo is required. I do not get why

py-3.x-stf

alias echo.setup.sdc='non_redacted=$(eval echo $DPM_CMD_START_SDC) && echo ${non_redacted//$DPM_PASSWORD/xxxx}'
alias setup.sdc='echo.setup.sdc && eval $DPM_CMD_START_SDC'

function start_sdc_and_set_authoring_var() {
    echo.setup.sdc
    sdc_line=$(eval $DPM_CMD_START_SDC | tee /dev/tty | grep "can be followed along")
    export SCH_AUTHORING_SDC=$(echo $sdc_line | grep -o '\S*$')
    echo "SCH_AUTHORING_SDC is $SCH_AUTHORING_SDC"
}

alias setup.sdcs='setup.sdc && start_sdc_and_set_authoring_var'
alias ch-setup-sdc=setup.sdc
alias ch-setup-sdcs=setup.sdcs

export HELP="Helpful commands. 'echo \$HELP' if you need a reminder.
# Start SDCs. Uses \$SDC_VERSION and \$SDC_START_EXTRA_PARAMS
setup.sdcs
# Start a single SDC
setup.sdc
# Sample STF execution. Warning:
# - dpm-tests are written under lots of assumptions that are unlikely to hold true in your org
# - if your test uses the sch_user annotation, you'll get an invite to the address specified in
#   'op://Employee/$ONE_PASSWORD_ITEM/new_user_email' and the test will fail. You'll need to
#   accept the invite to set the password, modify the entry in 'tests_users.yaml' and re-run the test. 
$DPM_CMD_SAMPLE_STF"

echo ---
echo $HELP

