#!/usr/bin/env bash

# Copyright (c) 2022 Werbot, Inc.
#
# This is a simple script that can be downloaded and run from
# https://install.werbot.com in order to install the Werbot
# command-line tools and all Werbot components.
#
# Run commands:
# bash <(curl -L -Ss https://install.werbot.com) --domain=domain.com
# bash <(wget -qO- https://install.werbot.com) --domain=domain.com
#
# Parameters:
# --domain     - Main domain for work project. For this domain.
#                You need to create DNS records CNAME type for subdomain "api" and "app"
# --geolite    - Link to update the GeoLite2-Country database
# --cf-email   - Cloudflare email
# --cf-api-key - Cloudflare API key

if readlink /proc/$$/exe | grep -q "dash"; then
  echo 'This installer needs to be run with "bash", not "sh".'
  exit
fi

# Main settings
APP_CDN="https://app.werbot.com"
LICENSE_CDN="https://license.werbot.com"
WERBOT_DIR="/home/werbot"

# Service settings
DOMAIN=""
GEOLITE_DATABASE="https://install.werbot.com/GeoLite2-Country.mmdb"
CLOUDFLARE_EMAIL=""
CLOUDFLARE_API_KEY=""

# Global setting
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
  echo "          Install Enterprise version"
  echo "---------------------------------------------"

  # Check options
  for flag in "$@"; do
    case $flag in
    --domain=*)
      DOMAIN="${flag#*=}"
      shift
      ;;
    --geolite=*)
      GEOLITE_DATABASE="${flag#*=}"
      shift
      ;;
    --cf-email=*)
      CLOUDFLARE_EMAIL="${flag#*=}"
      shift
      ;;
    --cf-api-key=*)
      CLOUDFLARE_API_KEY="${flag#*=}"
      shift
      ;;
    esac
  done

  echo ""
  echo "To begin the installation, you must set up DNS records"
  echo "for your domain. Detailed information on how to do"
  echo "this is on the page https://werbot.com/doc/install."
  echo ""
  echo "${COLOR_RED}Currently support only Cloudflare DNS provider."
  echo "This is required to issue an SSL certificate."
  echo "After installation, you can install your certificate.${COLOR_RESET}"
  echo ""
  read -p "Have you set up DNS entries for your domain (y/n)? " user_answer
  case "$user_answer" in
  "y" | "Y") echo "" ;;
  *) exit ;;
  esac

  # Domain parameters
  domain_regex='(?=^.{1,254}$)(^(?>(?!\d+\.)[a-zA-Z0-9_\-]{1,63}\.?)+(?:[a-zA-Z]{2,})$)'
  if [[ -z "$(echo $DOMAIN | grep -P $domain_regex)" ]]; then
    read -rp "Domain name: " -e -i "$DOMAIN" DOMAIN
    if [[ -z "$(echo $DOMAIN | grep -P $domain_regex)" ]]; then
      echo "${COLOR_RED}$DOMAIN${COLOR_RESET} - is not validate domain"
      exit 1
    fi
  fi

  # Cloudflare email parameters
  cf_email_regex='(^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$)'
  if [[ -z "$(echo $CLOUDFLARE_EMAIL | grep -P $cf_email_regex)" ]]; then
    read -rp "Cloudflare email: " -e -i "${CLOUDFLARE_EMAIL}" CLOUDFLARE_EMAIL
    if [[ -z "$(echo $CLOUDFLARE_EMAIL | grep -P $cf_email_regex)" ]]; then
      echo "${COLOR_RED}$CLOUDFLARE_EMAIL${COLOR_RESET} - is not validate email"
      exit 1
    fi
  fi

  # Cloudflare API key parameters
  cf_api_key_regex='(^.{37}$)'
  if [[ -z "$(echo $CLOUDFLARE_API_KEY | grep -P $cf_api_key_regex)" ]]; then
    read -rp "Cloudflare API key: " -e -i "${CLOUDFLARE_API_KEY}" CLOUDFLARE_API_KEY
    if [[ -z "$(echo $CLOUDFLARE_API_KEY | grep -P $cf_api_key_regex)" ]]; then
      echo "${COLOR_RED}$CLOUDFLARE_API_KEY${COLOR_RESET} - is not validate API key"
      exit 1
    fi
  fi

  # Checking operating system
  local OS
  print_header "Checking operating system"
  OS=$(uname -s)
  case "$OS" in
  Linux) OS=linux ;;
  *) print_answer "NOT SUPPORTED" red && exit 1 ;;
  esac
  print_answer "SUCCESS" green
  # ------------------------------------------------

  # Checking CPU architecture
  local CPU
  print_header "Checking CPU architecture"
  CPU=$(uname -m)
  case "$CPU" in
  x86_64 | x86-64 | x64 | amd64) CPU=amd64 ;;
  *) print_answer "NOT SUPPORTED" red && exit 1 ;;
  esac
  print_answer "SUCCESS" green
  # ------------------------------------------------

  # Installing jq
  print_header "Checking install jq"
  command_exists jq || {
    print_answer "NEED INSTALLATION" yellow
    print_header "Installing jq"
    sudo curl -L https://github.com/stedolan/jq/releases/download/$(get_latest_release "stedolan/jq")/jq-linux64 -o /usr/local/bin/jq >/dev/null 2>&1
    sudo chmod +x /usr/local/bin/jq
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
    curl -sSf https://get.docker.com | sh >/dev/null 2>&1
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
    sudo curl -L https://github.com/docker/compose/releases/download/$(get_latest_release "docker/compose")/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose >/dev/null 2>&1
    sudo chmod +x /usr/local/bin/docker-compose
    command_exists docker-compose command_exists || {
      print_answer "ERROR" red && exit 1
    }
  }
  print_answer "SUCCESS" green
  # ------------------------------------------------

  # Create new user
  if ! getent passwd werbot >/dev/null; then
    print_header "Adding a new werbot user"
    sudo useradd -m -d $WERBOT_DIR werbot -s /bin/bash
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

  sudo su - werbot -c "git clone https://github.com/werbot/install.werbot.com.git $WERBOT_DIR/service/tmp" >/dev/null 2>&1
  sudo su - werbot -c "mv $WERBOT_DIR/service/tmp/cfg/grafana $WERBOT_DIR/service/grafana" >/dev/null 2>&1
  sudo su - werbot -c "mv $WERBOT_DIR/service/tmp/cfg/haproxy $WERBOT_DIR/service/haproxy" >/dev/null 2>&1
  sudo su - werbot -c "mv $WERBOT_DIR/service/tmp/cfg/loki $WERBOT_DIR/service/loki" >/dev/null 2>&1
  sudo su - werbot -c "mv $WERBOT_DIR/service/tmp/cfg/prometheus $WERBOT_DIR/service/prometheus" >/dev/null 2>&1
  sudo su - werbot -c "mv $WERBOT_DIR/service/tmp/cfg/promtail $WERBOT_DIR/service/promtail" >/dev/null 2>&1

  sudo su - werbot -c "mkdir -p $WERBOT_DIR/service/{core,postgres,postgres/ca}"

  sudo su - werbot -c "cd $WERBOT_DIR/service/postgres/ca/
    openssl req -new -text -passout pass:abcd -subj /CN=Werbot -out server.req -keyout privkey.pem
    openssl rsa -in privkey.pem -passin pass:abcd -out server.key
    openssl req -x509 -in server.req -text -key server.key -out server.crt
    chmod 600 server.key
    sudo chown 70 server.key" >/dev/null 2>&1

  sudo su - werbot -c "ssh-keygen -q -t rsa -b 4096 -N '' -f $WERBOT_DIR/service/core/server_key <<<y
    rm $WERBOT_DIR/service/core/server_key.pub
    chmod 664 $WERBOT_DIR/service/core/server_key" >/dev/null 2>&1

  # TODO: create $WERBOT_DIR/service/.env

  sudo su - werbot -c "curl -s -o $WERBOT_DIR/service/core/GeoLite2-Country.mmdb $GEOLITE_DATABASE"

  # TODO: update domain $WERBOT_DIR/service/haproxy/config.cfg
  # TODO: download $WERBOT_DIR/service/docker-compose.yaml

  sudo chown 10001:10001 $WERBOT_DIR/service/core/
  sudo rm -rf $WERBOT_DIR/service/tmp
  print_answer "SUCCESS" green
  # ------------------------------------------------

  # Pulling docker containers (~2min)
  print_header "Pulling docker containers (~2min)"
  # docker-compose -f $WERBOT_DIR/service/docker-compose.yaml pull >/dev/null 2>&1
  print_answer "SUCCESS" green
  # ------------------------------------------------

  echo "My external ip: $(get_ip)"
}

install "$@" || exit 1
