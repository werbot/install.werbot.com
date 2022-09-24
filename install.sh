#!/usr/bin/env sh

# Copyright (c) 2022 Werbot, Inc.

# This is a simple script that can be downloaded and run from
# https://install.werbot.com in order to install the Werbot
# command-line tools and all Werbot components.

set -u

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
RESET=$(tput sgr0)

OS=$(uname -s)
case "$OS" in
Linux) OS=linux ;;
Darwin) OS=darwin ;;
*) err "Error: unsupported operating system: $OS" ;;
esac

install() {
  echo "${RED}"
  echo " _    _  ____  ____  ____  _____  ____"
  echo "( \\/\\/ )( ___)(  _ \\(  _ \\(  _  )(_  _)"
  echo " )    (  )__)  )   / ) _ < )(_)(   )("
  echo "(__/\\__)(____)(_)\\_)(____/(_____) (__)"
  echo "${RESET}"
  echo "Install Enterprise version"
  echo "------------------------------------------------"

  # install docker
  command -v docker >/dev/null 2>&1 || {
    if [ "$OS" = darwin ]; then
      echo "install docker on Darwin"
    elif [ "$OS" = linux ]; then
      sudo apt install apt-transport-https ca-certificates curl software-properties-common &&
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - &&
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" &&
        sudo apt-get update &&
        sudo apt-get install -y docker-ce
    fi
  }

  # install docker-compose
  command -v docker-compose >/dev/null 2>&1 || {
    if [ "$OS" = darwin ]; then
      echo "install docker-compose on Darwin"
    elif [ "$OS" = linux ]; then
      sudo curl -L https://github.com/docker/compose/releases/download/$(curl -s "https://api.github.com/repos/docker/compose/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose &&
        sudo chmod +x /usr/local/bin/docker-compose
    fi
  }
}

err() {
  echo "$1" >&2 && exit 1
}

install "$@" || exit 1
