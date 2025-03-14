#!/bin/echo Run: source

source _env.prerequisites.zsh || return 1

name=$(basename $0); name=$name:r:s/env.//
echo $name
source set-prompt-for-env.zsh $name 

export ONE_PASSWORD_ITEM=local.3x
export DPM_PORT=${DPM_PORT:-20631}
export DPM_PORT_ADMIN=$(($DPM_PORT + 1))
export DPM_URL=http://host.docker.internal:$DPM_PORT
export DPM_USER=$(op read "op://Employee/$ONE_PASSWORD_ITEM/username")
export DPM_PASSWORD=$(op read "op://Employee/$ONE_PASSWORD_ITEM/password")
export SDC_VERSION=${SDC_VERSION:-5.8.0}
export SDC_START_EXTRA_PARAMS="--stage-lib orchestrator jdbc"

export DPM_REPO=$HOME/src/streamsets/domainserver-3x
export JAVA_HOME=$(/usr/libexec/java_home -v17)
export IDE_DBG_VSCODE='-Xdebug -Xrunjdwp:transport=dt_socket,server=y,address=5005,suspend=y'
export IDE_DBG_INTELLIJ='-agentlib:jdwp=transport=dt_socket,server=y,address=5005,suspend=y'

export DPM_CMD_SAMPLE_STF='stf \
  -v \
  --env-var DPM_USER \
  --env-var DPM_PASSWORD \
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
  --version $SDC_VERSION \
  --sch-server-url $DPM_URL \
  --sch-username $DPM_USER --sch-password $DPM_PASSWORD \
  --sch-executor-sdc-label $USER \
  $(echo $SDC_START_EXTRA_PARAMS)'
# This last echo is required. I do not get why

alias ch-set-dpm-dist='pushd $DPM_REPO/dist/target/dist/streamsets-dpm-*/ && export DPM_DIST=$(pwd) && popd'
alias setup.dpm-dist=ch-set-dpm-dist

alias ch-opts-set-debug-intellij='export DPM_JAVA_OPTS=$IDE_DBG_INTELLIJ;echo DPM will wait for the debugger.'
alias ch-opts-set-debug-vscode='export DPM_JAVA_OPTS=$IDE_DBG_VSCODE;echo DPM will wait for the debugger.'
alias ch-run='ch-set-dpm-dist && $DPM_DIST/bin/streamsets dpm'

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

unalias ch-rebuild-and-setup 2>/dev/null || true

export HELP="Helpful commands. 'echo \$HELP' if you need a reminder.
# Start the databases and SCH
python $HOME/src/streamsets/dpm-scripts/dpm-3x.py --batch --verbose run
# Restart SCH
python $HOME/src/streamsets/dpm-scripts/dpm-3x.py --verbose restart
# Set \$DPM_DIST
setup.dpm-dist
# Run and debug
ch-opts- ...
ch-run
# Start 2 SDCs and capture the SHC_AUTHORING_SDC
setup.sdcs
# Start a single SDC
setup.sdc
# Sample STF execution.
$DPM_CMD_SAMPLE_STF"

echo ---
echo $HELP
