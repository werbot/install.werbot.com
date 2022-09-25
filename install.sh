#!/usr/bin/env sh

# Copyright (c) 2022 Werbot, Inc.

# This is a simple script that can be downloaded and run from
# https://install.werbot.com in order to install the Werbot
# command-line tools and all Werbot components.

set -u

COLOR_RED=$(tput setaf 1)
COLOR_GREEN=$(tput setaf 2)
COLOR_YELLOW=$(tput setaf 3)
COLOR_RESET=$(tput sgr0)

command_exists() {
  command -v "$@" >/dev/null 2>&1
}

gen_password() {
  echo $(tr -cd 'a-zA-Z0-9!#$%&()*+?@[]^_' </dev/urandom | fold -w 32 | head -n 1)
}

print_success() {
  echo "${COLOR_GREEN}SUCCESS${COLOR_RESET}" >&2
}

print_alert() {
  echo "${COLOR_YELLOW}$1${COLOR_RESET}" >&2
}

print_error() {
  echo "${COLOR_RED}$1${COLOR_RESET}" >&2 && exit 1
}

print_header() {
  printf "%.45s " "$@ ........................................"
}

get_ip() {
  local IP=$(ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1)
  [ -z ${IP} ] && IP=$(curl -s https://ipv4.icanhazip.com)
  [ -z ${IP} ] && IP=$(curl -s https://ipinfo.io/ip)
  echo ${IP}
}

install() {
  echo "${COLOR_RED} _    _  ____  ____  ____  _____  ____"
  echo "( \\/\\/ )( ___)(  _ \\(  _ \\(  _  )(_  _)"
  echo " )    (  )__)  )   / ) _ < )(_)(   )("
  echo "(__/\\__)(____)(_)\\_)(____/(_____) (__)"
  echo "${COLOR_RESET}"
  echo "Install Enterprise version"
  echo "------------------------------------------------"

  # Checking operating system
  local OS
  print_header "Checking operating system"
  OS=$(uname -s)
  case "$OS" in
  Linux) OS=linux ;;
  Darwin) OS=darwin ;;
  *) print_error "NOT SUPPORTED" ;;
  esac
  print_success
  # ------------------------------------------------

  # Checking CPU architecture
  local CPU
  print_header "Checking CPU architecture"
  CPU=$(uname -m)
  case "$CPU" in
  x86_64 | x86-64 | x64 | amd64) CPU=amd64 ;;
  *) print_error "NOT SUPPORTED" ;;
  esac
  print_success
  # ------------------------------------------------

  # Installing jq
  print_header "Checking install jq"
  command_exists jq || {
    print_alert "INSTALLATION"
    print_header "Installing jq"
    if [ "$OS" = darwin ]; then
      brew install jq >/dev/null 2>&1
    elif [ "$OS" = linux ]; then
      sudo curl -L https://github.com/stedolan/jq/releases/download/$(curl -s "https://api.github.com/repos/stedolan/jq/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')/jq-linux64 -o /usr/local/bin/jq >/dev/null 2>&1
      sudo chmod +x /usr/local/bin/jq >/dev/null 2>&1
    fi
    command_exists jq || {
      print_error "ERROR"
    }
  }
  print_success
  # ------------------------------------------------

  # Installing docker
  print_header "Checking install docker"
  command_exists docker || {
    print_alert "INSTALLATION"
    print_header "Installing docker"
    if [ "$OS" = darwin ]; then
      brew install docker >/dev/null 2>&1
    elif [ "$OS" = linux ]; then
      curl -sSf https://get.docker.com | sh >/dev/null 2>&1
    fi
    command_exists docker || {
      print_error "ERROR"
    }
  }
  print_success
  # ------------------------------------------------

  # Installing docker-compose
  print_header "Checking install docker-compose"
  command_exists docker-compose || {
    print_alert "INSTALLATION"
    print_header "Installing docker-compose"
    if [ "$OS" = darwin ]; then
      brew install docker-compose >/dev/null 2>&1
    elif [ "$OS" = linux ]; then
      sudo curl -L https://github.com/docker/compose/releases/download/$(curl -s "https://api.github.com/repos/docker/compose/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose >/dev/null 2>&1
      sudo chmod +x /usr/local/bin/docker-compose >/dev/null 2>&1
    fi
    command_exists docker-compose command_exists || {
      print_error "ERROR"
    }
  }
  print_success
  # ------------------------------------------------

  # Create new user
  if ! getent passwd werbot >/dev/null; then
    print_header "Adding a new werbot user"
    sudo useradd -m -d /home/werbot werbot -s /bin/bash &>/dev/null
    echo "werbot ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/werbot >/dev/null
    sudo chmod 0440 /etc/sudoers.d/werbot
    sudo usermod -a -G sudo werbot
    sudo su - werbot -c "ssh-keygen -q -t ed25519 -N '' -f ~/.ssh/id_ed25519 <<<y" >/dev/null 2>&1
    sudo usermod -aG docker werbot &>/dev/null
    newgrp docker &>/dev/null
    print_success
  fi
  # ------------------------------------------------

  # Create structure service
  print_header "Create structure service"
  if ! [ -d /home/werbot/service ]; then
    sudo su - werbot -c "mkdir /home/werbot/service"
  fi
  print_success
  # ------------------------------------------------

  get_ip
}

install "$@" || exit 1
