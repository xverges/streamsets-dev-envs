#!/bin/echo Run: source

# Verify that the STF branch matches the CONTAINER_ENGINE
# Verify that the STF and podman/docker match
if stf --help 2>/dev/null | grep -q -- "--container-image"; then
    CONTAINER_ENGINE_STF=podman
else
    CONTAINER_ENGINE_STF=docker
fi
echo "Your STF branch uses $CONTAINER_ENGINE_STF"

if [ -n "$CONTAINER_ENGINE" ] && [ "$CONTAINER_ENGINE" != "$CONTAINER_ENGINE_STF" ]; then
    echo "Error: the value for CONTAINER_ENGINE does not match the one that STF expects ($CONTAINER_ENGINE_STF)"
    return 1
fi
export CONTAINER_ENGINE=$CONTAINER_ENGINE_STF
if ! $CONTAINER_ENGINE --version >/dev/null 2>&1; then
    echo "Error: Could not run $CONTAINER_ENGINE. Is it installed?"
    return 1
fi


# Set some variables to make commands independent
if [ "$CONTAINER_ENGINE" = "podman" ]; then
    export STF_CONTAINER_USE_TTY="--tty"
    export STF_DOCKER_PARAM=container
else
    export STF_CONTAINER_USE_TTY=""
    export STF_DOCKER_PARAM=docker
fi 
