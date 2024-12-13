#!/bin/echo Run: source

source _env.prerequisites.zsh || return 1



name=$(basename $0); name=$name:r:s/env.//
echo $name
source set-prompt-for-env.zsh $name 

# Build ####
export JAVA_HOME=$(/usr/libexec/java_home -v21)
export DPM_REPO=$HOME/src/streamsets/domainserver-master

# Auth ####
source _env.platform.zsh

# Tests ####
export DATAOPS_TEST_EMAIL_PASSWORD=${DATAOPS_TEST_EMAIL_PASSWORD:-UniterestingValue}
export SDC_VERSION=${SDC_VERSION:-5.12.0}
export SDC_START_EXTRA_PARAMS=${SDC_START_EXTRA_PARAMS:-"--stage-lib orchestrator jdbc"}

py-4.x-stf

alias setup.test-org-and-sdcs="$HOME/src/streamsets/dpm-scripts/platform/setup-control-plane-testing.sh && source $HOME/src/streamsets/dpm-scripts/platform/.stf-env.sh"

# Note 1: This is stolen from dpm-scripts/platform/setup-control-plane-testing.sh
# Note 2: Option "--enable-base-http-url private" made STF start unhappy
export DPM_CMD_START_SDC='stf \
  -v \
  --env-var FIREBASE_API_KEY \
  --env-var HOST_HOSTNAME=host.docker.internal \
  start sdc \
    --version $SDC_VERSION \
    --aster-server-url $ASTER_URL \
    --sch-credential-id $CRED_ID \
    --sch-token $CRED_TOKEN \
    --sch-executor-sdc-label $USER \
    $(echo $SDC_START_EXTRA_PARAMS)'

export DPM_CMD_SAMPLE_STF='stf \
  -v \
  --docker-extra-options="-p 5678:5678/tcp" \
  --env-var DATAOPS_TEST_EMAIL_PASSWORD \
  --env-var FIREBASE_API_KEY \
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

export HELP="Helpful commands. 'echo \$HELP' if you need a reminder.
# Start the databases and services
python $HOME/src/streamsets/dpm-scripts/dpm-platform.py --batch --verbose run
# Restart the services
python $HOME/src/streamsets/dpm-scripts/dpm-platform.py --verbose restart
# Create test org + create credentials + start SDCs. Uses \$SDC_VERSION and \$SDC_START_EXTRA_PARAMS
setup.test-org-and-sdcs
# Set the environment vars needed for STF tests (updates in 1pass).
set_cred_from_aster_dev
# Start a single SDC
setup.sdc
# Sample STF execution.
$DPM_CMD_SAMPLE_STF"

echo $HELP