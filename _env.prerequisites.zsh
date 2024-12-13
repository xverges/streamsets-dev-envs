#!/bin/echo Run: source

#check if container environment is correctly set
declare -A container_env

container_env=( [Rancher]=.rd [Colima]=.colima [Docker]=.docker ) 

if [ ! -S /var/run/docker.sock ]; then 
  echo '/var/run/docker.sock not found. Run:'
  for value in ${(v)container_env}; do
    if [ -S $HOME/$value/docker.sock ]; then 
      echo "sudo ln -s $HOME/$value/docker.sock /var/run/docker.sock"
      return 1
    fi
  done
  echo 'No containers env running start one of ${(k)container_env}'
  return 1 
fi

if grep -qE 'credsStore.*osx' ~/.docker/config.json; then
  echo 'docker config for credsStore incompatible with STF. Run:'
  echo "sed -i '' '/credsStore/d' ~/.docker/config.json"
  return 1
fi

#check if one password CLI is installed
if ! type op > /dev/null; then
  echo "Please install 1Password CLI and turn on integration"
  echo "https://developer.1password.com/docs/cli/get-started/"
  echo "https://developer.1password.com/docs/cli/app-integration/"
  return 1
fi

#check aliases for Python Virtual Envs
which py-4.x-stf > /dev/null
if [ $? -ne 0 ]; then
  echo "Please check your pyEnv for 4x and its alias (should be set to py-4.x-stf)"
  return 1
fi

which py-3.x-stf > /dev/null
if [ $? -ne 0 ]; then
  echo "Please check your pyEnv for 3x and its alias (should be set to py-3.x-stf)"
  return 1
fi