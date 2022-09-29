#!/usr/bin/env sh

# Copyright (c) 2022 Werbot, Inc.

# This is a simple script that can be downloaded and run from
# https://install.werbot.com in order to add new server in the Werbot.

# Main settings
APP_CDN=${APP_CDN:-"https://app.werbot.com"}
PROJECT_TOKEN=${PROJECT_TOKEN:-0}

# Global setting
COLOR_GREY=$(tput setaf 0)
COLOR_RED=$(tput setaf 1)
COLOR_GREEN=$(tput setaf 2)
COLOR_YELLOW=$(tput setaf 3)
COLOR_RESET=$(tput sgr0)

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
    head -n 1)
  [ -z ${IP} ] && IP=$(curl -s https://ipv4.icanhazip.com)
  [ -z ${IP} ] && IP=$(curl -s https://ipinfo.io/ip)
  [ -z ${IP} ] && IP=$(curl -s https://ipv6.icanhazip.com)
  echo ${IP}
}

install() {
  clear
  echo ""
  echo "#######################################################"
  echo "#${COLOR_RED}                            _            _           ${COLOR_RESET}#"
  echo "#${COLOR_RED}        _  _  _ _____  ____| |__   ___ _| |_         ${COLOR_RESET}#"
  echo "#${COLOR_RED}       | || || | ___ |/ ___)  _ \ / _ (_   _)        ${COLOR_RESET}#"
  echo "#${COLOR_RED}       | || || | ____| |   | |_) ) |_| || |_         ${COLOR_RESET}#"
  echo "#${COLOR_RED}        \_____/|_____)_|   |____/ \___/  \__)        ${COLOR_RESET}#"
  echo "#                                                     #"
  echo "#             Add new server in the Werbot            #"
  echo "#                                                     #"
  echo "#######################################################"
  echo ""

  echo "My external ip: $(get_ip)"

  #Check system
  local release=''
  local systemPackage=''

  if [ -f /etc/redhat-release ]; then
    release="centos"
    systemPackage="yum"
  elif grep -Eqi "debian|raspbian" /etc/issue; then
    release="debian"
    systemPackage="apt"
  elif grep -Eqi "ubuntu" /etc/issue; then
    release="ubuntu"
    systemPackage="apt"
  elif grep -Eqi "centos|red hat|redhat" /etc/issue; then
    release="centos"
    systemPackage="yum"
  elif grep -Eqi "debian|raspbian" /proc/version; then
    release="debian"
    systemPackage="apt"
  elif grep -Eqi "ubuntu" /proc/version; then
    release="ubuntu"
    systemPackage="apt"
  elif grep -Eqi "centos|red hat|redhat" /proc/version; then
    release="centos"
    systemPackage="yum"
  fi

  echo "Release: $release, Package: $systemPackage" 

}

install "$@" || exit 1
