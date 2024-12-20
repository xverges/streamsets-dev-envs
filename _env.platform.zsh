#!/bin/echo Run: source

source _env.prerequisites.zsh || return 1
source _env.credentials.zsh || return 1
get_from_1pass
echo "Auth set from 1Password"

name=${1:-$ONE_PASSWORD_ITEM}
echo $name
source set-prompt-for-env.zsh $name 

# Tests ####
export DATAOPS_TEST_EMAIL_PASSWORD=${DATAOPS_TEST_EMAIL_PASSWORD:-UniterestingValue}
export SDC_START_EXTRA_PARAMS="--stage-lib orchestrator jdbc"

py-4.x-stf

export DPM_CMD_START_SDC='stf \
  --env-var FIREBASE_API_KEY \
  --env-var HOST_HOSTNAME=host.docker.internal \
start sdc \
  --enable-base-http-url private \
  --version $SDC_VERSION \
  --aster-server-url $ASTER_URL \
  --sch-credential-id $CRED_ID \
  --sch-token $CRED_TOKEN \
  --sch-executor-sdc-label $USER \
  $(echo $SDC_START_EXTRA_PARAMS)'
# This last echo is required. I do not get why

export DPM_CMD_SAMPLE_STF='stf \
  -v \
  --docker-extra-options="-p 5678:5678/tcp" \
  --env-var DATAOPS_TEST_EMAIL_PASSWORD \
test \
  -v -ra --capture=no \
  --sch-credential-id $CRED_ID \
  --sch-token $CRED_TOKEN \
  --aster-server-url $ASTER_LOGIN_URL \
  --aster-email $ASTER_EMAIL \
  --aster-email-password $ASTER_EMAIL_PWD \
  --sch-authoring-sdc $SCH_AUTHORING_SDC \
  --sch-executor-sdc-label $USER \
control_plane/jobs/test_jobs.py::test_simple_job_lifecycle'

alias echo.setup.sdc='non_redacted=$(eval echo $DPM_CMD_START_SDC) && echo ${non_redacted//$CRED_TOKEN/xxxx}'
alias setup.sdc='echo.setup.sdc && eval $DPM_CMD_START_SDC'

function start_sdc_and_set_authoring_var() {
    echo.setup.sdc
    sdc_line=$(eval $DPM_CMD_START_SDC | tee /dev/tty | grep "SDC ID:")
    export SCH_AUTHORING_SDC=$(echo $sdc_line | sed 's/.*\: //')
    echo "SCH_AUTHORING_SDC is $SCH_AUTHORING_SDC"
}

alias setup.sdcs='setup.sdc && start_sdc_and_set_authoring_var'
alias ch-setup-sdc=setup.sdc
alias ch-setup-sdcs=setup.sdcs

export HELP="Helpful commands. 'echo \$HELP' if you need a reminder.
# Start 2 SDCs and capture the SHC_AUTHORING_SDC
setup.sdcs
# Start a single SDC
setup.sdc
# Sample STF execution.
$DPM_CMD_SAMPLE_STF"

echo ---
echo $HELP