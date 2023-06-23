#!/usr/bin/env bash

set -eE

help_msg='Usage: run.sh --config PATH --global-config PATH --output PATH --zerostate PATH

Options:
  -h,--help                               Print this help message and exit
  --config PATH                            Path to the service config file
  --global-config PATH                     Path to the global config file
'

print_help() {
  echo "$help_msg"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  -h | --help)
    print_help
    exit 0
    ;;
  -c | --config)
    config="$2"
    shift
    if [ "$#" -gt 0 ]; then
      shift
    else
      # shellcheck disable=SC2028
      echo 'ERROR: Expected service config file\n'
      print_help
      exit 1
    fi
    ;;
  -g | --global-config)
    global_config="$2"
    shift
    if [ "$#" -gt 0 ]; then
      shift
    else
      # shellcheck disable=SC2028
      echo 'ERROR: Expected global config file\n'
      print_help
      exit 1
    fi
    ;;
  *) # unknown option
    echo -e "ERROR: Unknown option $1 \n"
    print_help
    exit 1
    ;;
  esac
done

[[ -z $config ]] && {
  echo "ERROR: path to config file not set"
  print_help
  exit 1
}

[[ -z $global_config ]] && {
  echo "ERROR: path to global config file not set"
  print_help
  exit 1
}

# Update ADNL ip address
ip_address=$(hostname -i)
yq eval ".node_settings.adnl_public_ip = \"$ip_address\"" -i "$config"

# TODO
sleep 300

everscale-monitoring run --config "$config" --global-config "$global_config"
