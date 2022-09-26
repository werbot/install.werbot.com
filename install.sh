#!/usr/bin/env sh

# Copyright (c) 2022 Werbot, Inc.

# This is a simple script that can be downloaded and run from
# https://install.werbot.com in order to install the Werbot
# command-line tools and all Werbot components.

set -u

APP_CDN="https://app.werbot.com"
LICENSE_CDN="https://license.werbot.com"

DOMAIN=${DOMAIN:-}
CLOUDFLARE_EMAIL=${CLOUDFLARE_EMAIL:-}
CLOUDFLARE_API_KEY=${CLOUDFLARE_API_KEY:-}

COLOR_GREY=$(tput setaf 0)
COLOR_RED=$(tput setaf 1)
COLOR_GREEN=$(tput setaf 2)
COLOR_YELLOW=$(tput setaf 3)
COLOR_RESET=$(tput sgr0)

command_exists() {
  command -v "$@" >/dev/null 2>&1
}

gen_password() {
  tr -cd 'a-zA-Z0-9!#$%&()*+?@[]^_' </dev/urandom |
    fold -w 32 |
    head -n 1
}

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

get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" |
    grep '"tag_name":' |
    sed -E 's/.*"([^"]+)".*/\1/'
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
  echo "${COLOR_RED} _    _  ____  ____  ____  _____  ____"
  echo "( \\/\\/ )( ___)(  _ \\(  _ \\(  _  )(_  _)"
  echo " )    (  )__)  )   / ) _ < )(_)(   )("
  echo "(__/\\__)(____)(_)\\_)(____/(_____) (__)"
  echo "${COLOR_RESET}"
  echo "Install Enterprise version"
  echo "------------------------------------------------"

  for flag in "$@"; do
    case $flag in
    domain=?*) DOMAIN=${1#*=} ;;
    cloudflare_email=?*) CLOUDFLARE_EMAIL=${1#*=} ;;
    cloudflare_api_key=?*) CLOUDFLARE_API_KEY=${1#*=} ;;
    esac
  done

  echo ""
  echo "To begin the installation, you must set up DNS records"
  echo "for your domain. Detailed information on how to do"
  echo "this is on the page https://werbot.com/doc/install."
  echo ""
  echo "${COLOR_RED}We currently only support DNS provider Cloudflare."
  echo "This is required to issue an SSL certificate."
  echo "After installation, you can install your certificate.${COLOR_RESET}"
  echo ""
  printf "Have you set up DNS entries for your domain (y/n)? "
  read -r user_answer
  if echo "$user_answer" | grep -iq "^y"; then
    echo ""
  else
    exit
  fi

  # Domain parameters
  if [ -z "${DOMAIN}" ]; then
    printf "Domain name: "
    read -r DOMAIN
    if [ -z "$(echo $DOMAIN | grep -P '(?=^.{1,254}$)(^(?>(?!\d+\.)[a-zA-Z0-9_\-]{1,63}\.?)+(?:[a-zA-Z]{2,})$)')" ]; then
      echo "$DOMAIN is not validate domain"
      exit
    fi
  fi

  # Cloudflare email parameters
  if [ -z "${CLOUDFLARE_EMAIL}" ]; then
    printf "Cloudflare email: "
    read -r CLOUDFLARE_EMAIL
    if [ -z "$(echo $CLOUDFLARE_EMAIL | grep -P '(^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$)')" ]; then
      echo "$CLOUDFLARE_EMAIL is not validate email"
      exit
    fi
  fi

  # Cloudflare API key parameters
  if [ -z "${CLOUDFLARE_API_KEY}" ]; then
    printf "Cloudflare API key: "
    read -r CLOUDFLARE_API_KEY
    if [ -z "$(echo $CLOUDFLARE_API_KEY | grep -P '(^.{37}$)')" ]; then
      echo "$CLOUDFLARE_API_KEY is not validate API key"
      exit
    fi
  fi

  # Checking operating system
  local OS
  print_header "Checking operating system"
  OS=$(uname -s)
  case "$OS" in
  Linux) OS=linux ;;
  Darwin) OS=darwin ;;
  *) print_answer "NOT SUPPORTED" && exit 1 ;;
  esac
  print_answer "SUCCESS" green
  # ------------------------------------------------

  # Checking CPU architecture
  local CPU
  print_header "Checking CPU architecture"
  CPU=$(uname -m)
  case "$CPU" in
  x86_64 | x86-64 | x64 | amd64) CPU=amd64 ;;
  *) print_answer "NOT SUPPORTED" && exit 1 ;;
  esac
  print_answer "SUCCESS" green
  # ------------------------------------------------

  # Installing jq
  print_header "Checking install jq"
  command_exists jq || {
    print_answer "NEED INSTALLATION" yellow
    print_header "Installing jq"
    if [ "$OS" = darwin ]; then
      brew install jq >/dev/null 2>&1
    elif [ "$OS" = linux ]; then
      sudo curl -L https://github.com/stedolan/jq/releases/download/$(get_latest_release "stedolan/jq")/jq-linux64 -o /usr/local/bin/jq >/dev/null 2>&1
      sudo chmod +x /usr/local/bin/jq
    fi
    command_exists jq || {
      print_answer "ERROR" red && exit 1
    }
  }
  print_answer "SUCCESS" green
  # ------------------------------------------------

  # Installing docker
  print_header "Checking install docker"
  command_exists docker || {
    print_answer "NEED INSTALLATION" yellow
    print_header "Installing docker"
    if [ "$OS" = darwin ]; then
      brew install docker >/dev/null 2>&1
    elif [ "$OS" = linux ]; then
      curl -sSf https://get.docker.com | sh >/dev/null 2>&1
    fi
    command_exists docker || {
      print_answer "ERROR" red && exit 1
    }
  }
  print_answer "SUCCESS" green
  # ------------------------------------------------

  # Installing docker-compose
  print_header "Checking install docker-compose"
  command_exists docker-compose || {
    print_answer "NEED INSTALLATION" yellow
    print_header "Installing docker-compose"
    if [ "$OS" = darwin ]; then
      brew install docker-compose >/dev/null 2>&1
    elif [ "$OS" = linux ]; then
      sudo curl -L https://github.com/docker/compose/releases/download/$(get_latest_release "docker/compose")/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose >/dev/null 2>&1
      sudo chmod +x /usr/local/bin/docker-compose
    fi
    command_exists docker-compose command_exists || {
      print_answer "ERROR" red && exit 1
    }
  }
  print_answer "SUCCESS" green
  # ------------------------------------------------

  # Create new user
  if ! getent passwd werbot >/dev/null; then
    print_header "Adding a new werbot user"
    sudo useradd -m -d /home/werbot werbot -s /bin/bash
    echo "werbot ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/werbot >/dev/null 2>&1
    sudo chmod 0440 /etc/sudoers.d/werbot
    sudo usermod -a -G sudo werbot
    sudo su - werbot -c "ssh-keygen -q -t ed25519 -N '' -f ~/.ssh/id_ed25519 <<<y"
    sudo usermod -aG docker werbot
    # newgrp docker
    print_answer "SUCCESS" green
  fi
  # ------------------------------------------------

  # Create structure service
  print_header "Create structure service"

  sudo su - werbot -c "git clone https://github.com/werbot/install.werbot.com.git /home/werbot/service/tmp" >/dev/null 2>&1
  sudo su - werbot -c "mv /home/werbot/service/tmp/cfg/grafana /home/werbot/service/grafana" >/dev/null 2>&1
  sudo su - werbot -c "mv /home/werbot/service/tmp/cfg/haproxy /home/werbot/service/haproxy" >/dev/null 2>&1
  sudo su - werbot -c "mv /home/werbot/service/tmp/cfg/loki /home/werbot/service/loki" >/dev/null 2>&1
  sudo su - werbot -c "mv /home/werbot/service/tmp/cfg/prometheus /home/werbot/service/prometheus" >/dev/null 2>&1
  sudo su - werbot -c "mv /home/werbot/service/tmp/cfg/promtail /home/werbot/service/promtail" >/dev/null 2>&1

  sudo su - werbot -c "mkdir -p /home/werbot/service/{core,postgres,postgres/ca}"

  sudo su - werbot -c "cd /home/werbot/service/postgres/ca/
    openssl req -new -text -passout pass:abcd -subj /CN=Werbot -out server.req -keyout privkey.pem
    openssl rsa -in privkey.pem -passin pass:abcd -out server.key
    openssl req -x509 -in server.req -text -key server.key -out server.crt
    chmod 600 server.key
    sudo chown 70 server.key" >/dev/null 2>&1

  sudo su - werbot -c "ssh-keygen -q -t rsa -b 4096 -N '' -f /home/werbot/service/core/server_key <<<y
    rm /home/werbot/service/core/server_key.pub
    chmod 664 /home/werbot/service/core/server_key" >/dev/null 2>&1

  # TODO: create /home/werbot/service/.env

  sudo su - werbot -c "curl -s -o /home/werbot/service/core/GeoLite2-Country.mmdb https://install.werbot.com/GeoLite2-Country.mmdb"

  # TODO: update domain /home/werbot/service/haproxy/config.cfg
  # TODO: download /home/werbot/service/docker-compose.yaml

  sudo chown 10001:10001 /home/werbot/service/core/
  sudo rm -rf /home/werbot/service/tmp
  print_answer "SUCCESS" green
  # ------------------------------------------------

  # Pulling docker containers (~2min)
  print_header "Pulling docker containers (~2min)"
  # docker-compose -f /home/werbot/service/docker-compose.yaml pull >/dev/null 2>&1
  print_answer "SUCCESS" green
  # ------------------------------------------------

  echo "My external ip: $(get_ip)"
}

install "$@" || exit 1
