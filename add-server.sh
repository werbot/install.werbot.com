#!/usr/bin/env sh

# Copyright (c) 2022 Werbot, Inc.

# This is a simple script that can be downloaded and run from
# https://install.werbot.com in order to add new server in the Werbot.

# curl -sSL https://install.werbot.com/add-server.sh | sudo sh --token=token
# wget -qO- https://install.werbot.com/add-server.sh | sudo sh --token=token

# Main settings
API_CDN="https://api.werbot.com"
PROJECT_TOKEN=""

# Global setting
COLOR_GREY=$(tput setaf 0)
COLOR_RED=$(tput setaf 1)
COLOR_GREEN=$(tput setaf 2)
COLOR_YELLOW=$(tput setaf 3)
COLOR_RESET=$(tput sgr0)

if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be executed with root privileges."
  exit 1
fi

print_answer() {
  local COLOR="$COLOR_RESET"
  for flag in "$@"; do
    case $flag in
    grey) COLOR=$COLOR_GREY ;;
    green) COLOR=$COLOR_GREEN ;;
    yellow) COLOR=$COLOR_YELLOW ;;
    red) COLOR=$COLOR_RED ;;
    esac
  done
  echo "${COLOR}$1${COLOR_RESET}" >&2
}

print_header() {
  printf "%.45s " "$@ ........................................"
}

get_ip() {
  local IP=$(ip addr |
    egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' |
    egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." |
    head -n 1) >/dev/null 2>&1
  [ -z ${IP} ] && IP=$(curl -s ${API_CDN}/ip)
  echo ${IP}
}

install() {
  clear
  echo "${COLOR_RED}                        _            _   "
  echo "    _  _  _ _____  ____| |__   ___ _| |_ "
  echo "   | || || | ___ |/ ___)  _ \ / _ (_   _)"
  echo "   | || || | ____| |   | |_) ) |_| || |_ "
  echo "    \_____/|_____)_|   |____/ \___/  \__)"
  echo "${COLOR_RESET}"
  echo "         Add new server in the Werbot"
  echo "---------------------------------------------"

  # Check options
  for flag in "$@"; do
    case $flag in
    --token=*)
      PROJECT_TOKEN="${flag#*=}"
      shift
      ;;
    --api=*)
      API_CDN="${flag#*=}"
      shift
      ;;
    esac
  done

  # Checking operating system
  local SYSTEM
  local SYSTEM_PACKAGE
  print_header "Checking operating system"

  if [ -f /etc/os-release ]; then
    SYSTEM=$(awk -F= '$1 == "ID" {gsub("\"", ""); print$2}' /etc/os-release)
  elif [ -f /etc/redhat-release ]; then
    SYSTEM=$(awk '{print tolower($1)}' /etc/redhat-release)
  else
    not_supported
  fi

  SYSTEM=$(echo "${SYSTEM}" | tr '[:upper:]' '[:lower:]')
  case "${SYSTEM}" in
  "centos" | "red hat" | "redhat" | "rocky") SYSTEM_PACKAGE="yum" ;;
  "ubuntu" | "debian" | "fedora" | "raspbian") SYSTEM_PACKAGE="apt" ;;
  "freebsd" | "openbsd") SYSTEM_PACKAGE="pkg" ;;
  *)
    print_answer "ERROR" red
    echo ""
    echo "This script does not support the OS/Distribution on this machine."
    echo "If you feel that this is an error contact support@werbot.com"
    exit 1
    ;;
  esac
  print_answer "SUCCESS" green
  # ------------------------------------------------

  # Verifying project token
  print_header "Verifying project token"
  if [ -z "$(echo ${PROJECT_TOKEN} | grep -P '(^.{5}$)')" ]; then
    print_answer "ERROR" red
    echo ""
    echo "${COLOR_RED}$PROJECT_TOKEN${COLOR_RESET} - is not validate project token"
    exit 1
  fi
  print_answer "SUCCESS" green
  # ------------------------------------------------

  # Checking API server
  print_header "Checking API server"
  status=$(curl -o /dev/null --silent --head --write-out '%{http_code}' "${API_CDN}/ping")
  if [ ! $status -eq 200 ]; then
    print_answer "ERROR" red
    echo ""
    echo "API server unavailable"
    exit 1
  fi
  print_answer "SUCCESS" green
  # ------------------------------------------------

  # Adding a server to a project
  print_header "Adding a server to a project"
  local ip
  local port
  ip=$(get_ip)

  port=$(grep "^Port" /etc/ssh/sshd_config | awk '{print $2}')
  if [ -z "$port" ]; then
    port="22"
  fi

  # TODO send request to api
  # TODO add key to ssh and restart ssh

  print_answer "SUCCESS" green
  # ------------------------------------------------

  echo ""
  echo "System: $SYSTEM, Package: $SYSTEM_PACKAGE"
  echo "My external ip: $(get_ip)"
}

install "$@" || exit 1
