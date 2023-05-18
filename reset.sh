#!/usr/bin/env bash

set -eE

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

function print_help() {
  echo 'Usage: reset.sh [OPTIONS]'
  echo ''
  echo 'Options:'
  echo '  -h,--help    Print this help message and exit'
  echo '  -f,--full    Reset DB'
}

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
      -h|--help)
        print_help
        exit 0
      ;;
      -f|--full)
        FULL="true"
        shift # past argument
      ;;
      *) # unknown option
        echo 'ERROR: Unknown option'
        echo ''
        print_help
        exit 1
      ;;
  esac
done

echo "INFO: stopping nodes"
pkill -9 ton_node &>/dev/null || true

if ! [ -z $FULL ]; then
    echo "INFO: removing state"
    rm -rf "$SCRIPT_DIR/temp"
else
    echo "WARN: skipping state"
fi
