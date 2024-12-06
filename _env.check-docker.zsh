#!/bin/echo Run: source

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

