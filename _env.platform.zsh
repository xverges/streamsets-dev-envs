#!/bin/echo Run: source

source _env.check-docker.zsh || return 1

#check if one password CLI is installed
if ! type op > /dev/null; then
  echo "PLease install 1Password CLI and turn on integration"
  echo "https://developer.1password.com/docs/cli/get-started/"
  echo "https://developer.1password.com/docs/cli/app-integration/"
  return 1
fi

if [ -z "$ONE_PASSWORD_ITEM" ]; then
  echo 'The environment variable ONE_PASSWORD_ITEM needs to be set, and needs to specify a 1password item in the Employee vault.'
  echo 'The item needs to specify  `username`, `password`, `website`, `CRED_ID` and `CRED_TOKEN`'
  return 1
fi

name=${1:-$ONE_PASSWORD_ITEM}
echo $name
source set-prompt-for-env.zsh $name 

# Auth ####
export ASTER_EMAIL=$(op read "op://Employee/$ONE_PASSWORD_ITEM/username")
export ASTER_EMAIL_PWD=$(op read "op://Employee/$ONE_PASSWORD_ITEM/password")
export ASTER_LOGIN_URL=$(op read "op://Employee/$ONE_PASSWORD_ITEM/website")
export CRED_ID=$(op read "op://Employee/$ONE_PASSWORD_ITEM/CRED_ID")
export CRED_TOKEN=$(op read "op://Employee/$ONE_PASSWORD_ITEM/CRED_TOKEN")
export ASTER_URL=${ASTER_LOGIN_URL}
export ASTER_USER_EMAIL=${ASTER_EMAIL}
export ASTER_USER_PASSWORD=${ASTER_EMAIL_PWD}

if FIREBASE_API_KEY=$(op read "op://Employee/$ONE_PASSWORD_ITEM/firebase-api-key"); then
  export FIREBASE_API_KEY
elif FIREBASE_API_KEY=$(op read "op://Cloud Development/Firebase/LOCAL/Api key"); then
  echo "Using FIREBASE_API_KEY from op://Cloud Development/Firebase/LOCAL/Api key"
  export FIREBASE_API_KEY
else
  echo "FIREBASE_API_KEY not fond neigher in"
  echo "op://Employee/$ONE_PASSWORD_ITEM/firebase-api-key"
  echo "nor"
  echo "op://Cloud Development/Firebase/LOCAL/Api key"
  echo "Please set FIREBASE_API_KEY"
  retun 1
fi

# Tests ####
export DATAOPS_TEST_EMAIL_PASSWORD=${DATAOPS_TEST_EMAIL_PASSWORD:-UniterestingValue}
export SDC_START_EXTRA_PARAMS="--stage-lib orchestrator jdbc"

if command -v py-4.x-stf &> /dev/null; then
  py-4.x-stf
elif command -v 4x &> /dev/null; then
  4x
else
  echo "4.x Python env command not found"
  return 1
fi

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