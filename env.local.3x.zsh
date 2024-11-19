#!/bin/echo Run: source

source _env.check-docker.zsh || return 1

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
export JAVA_HOME=$(/usr/libexec/java_home -v1.8)

export DPM_CMD_SAMPLE_STF='stf \
  -v \
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

# TO-DO: make DPM_LOG and DPM_CONF dependant on $DPM_PORT, to be able to run multi-instance
alias setup.dbs-and-rebuild='python ~/src/streamsets/dpm-scripts/dpm-utils.py --host host.docker.internal \
   --port $DPM_PORT --expiration=30 --java-version 1.8 --dpm-dir $DPM_REPO \
   --database postgres --database-version 14.6 --build-tool maven \
   install clean && \
 ch-set-dpm-dist && \
 $DPM_DIST/dev/00-initpostgresql.sh && \
 $DPM_DIST/dev/01-initdb-java.sh && \
 $DPM_DIST/dev/02-initsecurity-java.sh $DPM_PORT && \
 $DPM_DIST/bin/streamsets dpmcli security systemId -c && \
 $DPM_DIST/bin/streamsets dpmcli security activationKey --dev --devExpires=30 && \
 find $DPM_DIST/etc -name "*.properties" -exec sed -i "" "s/18631/$DPM_PORT/g" {} \; && \
 find $DPM_DIST/etc -name "*.properties" -exec sed -i "" "s/18632/$DPM_PORT_ADMIN/g" {} \; && \
 find $DPM_DIST/etc -name "*.properties" -exec sed -i "" "s/\(dpm\.componentId=[a-zA-Z_]*\)000/\1${DPM_PORT}/g" {} \; && \
 sed -i "" "s/#org.quartz.jobStore.driverDelegateClass/org.quartz.jobStore.driverDelegateClass/" $DPM_DIST/etc/scheduler-app.properties'
# We are modifying the componentId so that we can have a fake HA environment with multiple instances on different ports

alias ch-run='ch-set-dpm-dist && $DPM_DIST/bin/streamsets dpm'

alias setup.test-org='ch-set-dpm-dist && \
 python ~/src/streamsets/dpm-scripts/dpm-utils.py \
   --dpm-dir $DPM_REPO --host host.docker.internal --port $DPM_PORT \
   create-test-org && \
 export adminToken=$(ch-get-token $DPM_URL admin@admin admin@admin) && \
 echo -n '\''[{"id": "dpm.enable.events","value": "true"},{"id": "dpm.enforce.permissions", "value": "true"}]'\'' | \
   http POST $DPM_URL/security/rest/v1/organization/test/configs \
   X-Requested-By:SCH X-SS-REST-CALL:true X-SS-User-Auth-Token:$adminToken && \
 http --pretty=format GET $DPM_URL/security/rest/v1/organization/test/configs \
   X-Requested-By:SCH X-SS-REST-CALL:true X-SS-User-Auth-Token:$adminToken | grep -e subscriptions -e "Enforce permissions" -A 4'

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

alias setup.test-org-and-sdcs='setup.test-org && setup.sdc && start_sdc_and_set_authoring_var'
alias ch-setup-test-org-and-sdcs=setup.test-org-and-sdcs
unalias ch-rebuild-and-setup 2>/dev/null || true

alias setup.test-users-yaml="yq -i '.Admin_test.password = strenv(DPM_PASSWORD)' $HOME/src/streamsets/dpm-tests/test_users.yaml"

export HELP="Helpful commands. 'echo \$HELP' if you need a reminder.
# Restart postgres, influxdb and rebuild
setup.dbs-and-rebuild
# Set \$DPM_DIST
setup.dpm-dist
# Run SCH
ch-run
# Create test org + start SDCs. Uses \$SDC_VERSION and \$SDC_START_EXTRA_PARAMS
setup.test-org-and-sdcs
# Start a single SDC
setup.sdc
# Setup test_users.yaml for STF testing
setup.test-users-yaml
# Sample STF execution.
$DPM_CMD_SAMPLE_STF"

echo ---
echo $HELP
