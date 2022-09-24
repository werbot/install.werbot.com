#!/usr/bin/env sh

# Copyright (c) 2022 Werbot, Inc.

# This is a simple script that can be downloaded and run from
# https://install.werbot.com in order to install the Werbot
# command-line tools and all Werbot components.

set -u

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
RESET=$(tput sgr0)

banner() {
  echo "${RED}"
  echo " _    _  ____  ____  ____  _____  ____"
  echo "( \\/\\/ )( ___)(  _ \\(  _ \\(  _  )(_  _)"
  echo " )    (  )__)  )   / ) _ < )(_)(   )("
  echo "(__/\\__)(____)(_)\\_)(____/(_____) (__)"
  echo "${RESET}"
  echo "Install Enterprise version"
  echo "------------------------------------------------"
}

install() {
  banner
}

err() {
  echo "$1" >&2 && exit 1
}

install "$@" || exit 1
