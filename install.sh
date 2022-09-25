#!/usr/bin/env sh

# Copyright (c) 2022 Werbot, Inc.

# This is a simple script that can be downloaded and run from
# https://install.werbot.com in order to install the Werbot
# command-line tools and all Werbot components.

set -u

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RESET=$(tput sgr0)

command_exists() {
  command -v "$@" >/dev/null 2>&1
}

print_header() {
  printf "%.45s " "$@ ........................................"
}

hello() {
  echo "${RED}"
  echo " _    _  ____  ____  ____  _____  ____"
  echo "( \\/\\/ )( ___)(  _ \\(  _ \\(  _  )(_  _)"
  echo " )    (  )__)  )   / ) _ < )(_)(   )("
  echo "(__/\\__)(____)(_)\\_)(____/(_____) (__)"
  echo "${RESET}"
  echo "Install Enterprise version"
  echo "------------------------------------------------"
}

check_and_install() {
  local OS
  local CPU

  # Checking operating system
  print_header "Checking operating system"
  OS=$(uname -s)
  case "$OS" in
  Linux) OS=linux ;;
  Darwin) OS=darwin ;;
  *) err "${RED}NOT SUPPORTED${RESET}" ;;
  esac
  echo "${GREEN}OK${RESET}"

  # Checking CPU architecture
  print_header "Checking CPU architecture"
  CPU=$(uname -m)
  case "$CPU" in
  x86_64 | x86-64 | x64 | amd64) CPU=amd64 ;;
  *) err "${RED}NOT SUPPORTED${RESET}" ;;
  esac
  echo "${GREEN}OK${RESET}"

  # Installing jq
  print_header "Checking install jq"
  command -v jq >/dev/null 2>&1 || {
    echo "${YELLOW}INSTALLATION${RESET}"
    print_header "Installing jq"
    if [ "$OS" = darwin ]; then
      brew install jq >/dev/null 2>&1
    elif [ "$OS" = linux ]; then
      sudo curl -L https://github.com/stedolan/jq/releases/download/$(curl -s "https://api.github.com/repos/stedolan/jq/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')/jq-linux64 -o /usr/local/bin/jq >/dev/null 2>&1
      sudo chmod +x /usr/local/bin/jq >/dev/null 2>&1
    fi
    command -v jq >/dev/null 2>&1 || {
      err "${RED}ERROR${RESET}"
    }
  }
  echo "${GREEN}OK${RESET}"

  # Installing docker
  print_header "Checking install docker"
  command -v docker >/dev/null 2>&1 || {
    echo "${YELLOW}INSTALLATION${RESET}"
    print_header "Installing docker"
    if [ "$OS" = darwin ]; then
      brew install docker >/dev/null 2>&1
    elif [ "$OS" = linux ]; then
      curl -sSf https://get.docker.com | sh >/dev/null 2>&1
    fi
    command -v docker >/dev/null 2>&1 || {
      err "${RED}ERROR${RESET}"
    }
  }
  echo "${GREEN}OK${RESET}"

  # Installing docker-compose
  print_header "Checking install docker-compose"
  command -v docker-compose >/dev/null 2>&1 || {
    echo "${YELLOW}INSTALLATION${RESET}"
    print_header "Installing docker-compose"
    if [ "$OS" = darwin ]; then
      brew install docker-compose >/dev/null 2>&1
    elif [ "$OS" = linux ]; then
      sudo curl -L https://github.com/docker/compose/releases/download/$(curl -s "https://api.github.com/repos/docker/compose/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose >/dev/null 2>&1
      sudo chmod +x /usr/local/bin/docker-compose >/dev/null 2>&1
    fi
    command -v docker-compose >/dev/null 2>&1 || {
      err "${RED}ERROR${RESET}"
    }
  }
  echo "${GREEN}OK${RESET}"
}

get_ip() {
  local IP=$(ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1)
  [ -z ${IP} ] && IP=$(curl -s https://ipv4.icanhazip.com)
  [ -z ${IP} ] && IP=$(curl -s https://ipinfo.io/ip)
  echo ${IP}
}

install() {
  hello
  check_and_install

  get_ip
}

err() {
  echo "$1" >&2 && exit 1
}

install "$@" || exit 1
