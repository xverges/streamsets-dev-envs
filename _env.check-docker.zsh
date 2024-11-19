#!/bin/echo Run: source


if [ ! -S $HOME/.rd/docker.sock ]; then 
  echo '$HOME/.rd/docker.sock not found.'
  echo 'Is Rancher Desktop running?'
  return 1 
fi

if [ ! -S /var/run/docker.sock ]; then 
  echo '/var/run/docker.sock not found. Run:'
  echo 'sudo ln -s $HOME/.rd/docker.sock /var/run/docker.sock'
  return 1 
fi

if grep -qE 'credsStore.*osx' ~/.docker/config.json; then
  echo 'docker config for credsStore incompatible with STF. Run:'
  echo "sed -i '' '/credsStore/d' ~/.docker/config.json"
  return 1
fi