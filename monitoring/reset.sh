#!/usr/bin/env bash

set -eE

function print_help() {
  echo 'Usage: reset.sh [OPTIONS]'
  echo ''
  echo 'Options:'
  echo '  -h,--help    Print this help message and exit'
}

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
      -h|--help)
        print_help
        exit 0
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
pkill -9 monitoring &>/dev/null || true
