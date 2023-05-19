#!/usr/bin/env bash

set -eE

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

function print_help() {
  echo 'Usage: run.sh --node-path PATH --tools-path PATH [OPTIONS]'
  echo ''
  echo 'Options:'
  echo '  -h,--help             Print this help message and exit'
  echo '  -n,--nodes N          Number of nodes to run'
  echo '  --node-path PATH      Path to the ever-node repo'
  echo '  --tools-path PATH     Path to the ever-node-tools repo'
  echo '  --rebuild-node        Build node before running the network'
  echo '  --rebuild-tools       Build tools before running the network'
}

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
      -h|--help)
        print_help
        exit 0
      ;;
      -n|--nodes)
        NODES="$2"
        shift # past argument
        if [ "$#" -gt 0 ]; then shift;
        else
          echo 'ERROR: Expected node count'
          echo ''
          print_help
          exit 1
        fi
      ;;
      --node-path)
        NODE_ROOT="$2"
        shift # past argument
        if [ "$#" -gt 0 ]; then shift;
        else
          echo 'ERROR: Expected ever-node repo path'
          echo ''
          print_help
          exit 1
        fi
      ;;
      --tools-path)
        TOOLS_ROOT="$2"
        shift # past argument
        if [ "$#" -gt 0 ]; then shift;
        else
          echo 'ERROR: Expected ever-node-tools repo path'
          echo ''
          print_help
          exit 1
        fi
      ;;
      --rebuild-node)
        REBUILD_NODE="true"
        shift # past argument
      ;;
      --rebuild-tools)
        REBUILD_TOOLS="true"
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

if [ -z $NODES ]; then
    NODES=5
    echo "WARN: using default node count $NODES"
fi

if [ -z $NODE_ROOT ]; then
    echo "ERROR: ever-node repo path not set"
    print_help
    exit 1
fi
NODE_ROOT="$(cd "$NODE_ROOT" && pwd -P)"

if [ -z $TOOLS_ROOT ]; then
    echo "ERROR: ever-node-tools repo path not set"
    print_help
    exit 1
fi
TOOLS_ROOT="$(cd "$TOOLS_ROOT" && pwd -P)"

pkill -9 ton_node &>/dev/null || true

RES_DIR="$SCRIPT_DIR/res"

TEMP_DIR="$SCRIPT_DIR/temp"
LOGS_DIR="$SCRIPT_DIR/logs"
NODE_TARGET="$NODE_ROOT/target/release"
TOOLS_TARGET="$TOOLS_ROOT/target/release"

if ! [ -z $REBUILD_NODE ]; then
    echo "INFO: rebuilding node"
    pushd "$NODE_ROOT" > /dev/null
    cargo build --release --features "telemetry"
    popd > /dev/null
fi

if ! [ -z $REBUILD_TOOLS ]; then
    echo "INFO: rebuilding node tools"
    pushd "$TOOLS_ROOT" > /dev/null
    cargo build --release
    popd > /dev/null
fi

NOWDATE=$(date +"%s")
NOWIP="127.0.0.1"

declare -A VALIDATOR_PUB_KEY_HEX=();
declare -A VALIDATOR_PUB_KEY_BASE64=();

echo "INFO: clearing temp dirs"
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

rm -rf "$LOGS_DIR"
mkdir -p "$LOGS_DIR"

# Fake config just to start nodes
cat "$RES_DIR/ton-global.config_1.json" > "$TEMP_DIR/ton-global.config.json"
cat "$RES_DIR/ton-global.config_2.json" >> "$TEMP_DIR/ton-global.config.json"

echo "INFO: preparing node configs..."

# 0 is full node
for (( N=0; N < $NODES; N++ ))
do
    echo "INFO: preparing configs for node #$N ..."

    cd "$TEMP_DIR"

    NODE_CONFIGS_DIR="$TEMP_DIR/node$N"
    mkdir -p "$NODE_CONFIGS_DIR"

    pkill -9 ton_node &>/dev/null || true

    NODE_KEYS=$("$TOOLS_TARGET/keygen")
    PUBLIC_KEY=$(echo "$NODE_KEYS" | jq -c .public)

    cp "$TEMP_DIR/ton-global.config.json" "$NODE_CONFIGS_DIR/ton-global.config.json"

    LOG_FILE_PATH="$LOGS_DIR/output_$N"
    ESCAPED_LOG_FILE_PATH=$(printf '%s\n' "$LOG_FILE_PATH" | sed -e 's/[\/&]/\\&/g')
    sed "s/LOG_FILE_PREFIX/$ESCAPED_LOG_FILE_PATH/g" "$RES_DIR/log_cfg.yml" > "$NODE_CONFIGS_DIR/log_cfg.yml"

    DEFAULT_CONFIG=$(cat "$RES_DIR/default_config.json")

    DEFAULT_CONFIG=$(echo "$DEFAULT_CONFIG" | sed "s/nodenumber/$N/g")
    DEFAULT_CONFIG=$(echo "$DEFAULT_CONFIG" | sed "s/0.0.0.0/$NOWIP/g")
    PORT=$(( 3000 + $N ))
    DEFAULT_CONFIG=$(echo "$DEFAULT_CONFIG" | sed "s/main_port/$PORT/g")
    PORT=$(( 4920 + $N ))
    DEFAULT_CONFIG=$(echo "$DEFAULT_CONFIG" | sed "s/control_port/$PORT/g")

    echo "$DEFAULT_CONFIG" > "$NODE_CONFIGS_DIR/default_config.json"

    pushd "$NODE_CONFIGS_DIR" > /dev/null
    "$NODE_TARGET/ton_node" --configs "$NODE_CONFIGS_DIR" --ckey "$PUBLIC_KEY" > /dev/null &
    popd > /dev/null

    echo "      * preparing console configs"
    sleep 5
    if [ ! -f "$NODE_CONFIGS_DIR/console_config.json" ]; then
        echo "ERROR: console_config.json does not exist"
        exit 1
    fi

    CONSOLE_CONFIG=$(jq ".client_key = $(echo "$NODE_KEYS" | jq .private)" "$NODE_CONFIGS_DIR/console_config.json")
    jq ".config = $CONSOLE_CONFIG" "$RES_DIR/console-template.json" > "$NODE_CONFIGS_DIR/console.json"

    rm "$NODE_CONFIGS_DIR/default_config.json"

    echo "      * preparing validator keys"
    CONSOLE_OUTPUT=$("$TOOLS_TARGET/console" -C "$NODE_CONFIGS_DIR/console.json" -c newkey | cut -c 92-)

    "$TOOLS_TARGET/console" -C "$NODE_CONFIGS_DIR/console.json" -c "addpermkey ${CONSOLE_OUTPUT} ${NOWDATE} 1610000000" > /dev/null

    CONSOLE_OUTPUT=$("$TOOLS_TARGET/console" -C "$NODE_CONFIGS_DIR/console.json" -c "exportpub ${CONSOLE_OUTPUT}")
    # echo $CONSOLE_OUTPUT
    VALIDATOR_PUB_KEY_HEX[$N]=$(echo "${CONSOLE_OUTPUT}" | grep 'imported key:' | awk '{print $3}')
    # VALIDATOR_PUB_KEY_BASE64[$N]=$(echo "${CONSOLE_OUTPUT}" | grep 'imported key:' | awk '{print $4}')
    # echo "INFO: VALIDATOR_PUB_KEY_HEX[$N] = ${VALIDATOR_PUB_KEY_HEX[$N]}"
    # echo "INFO: VALIDATOR_PUB_KEY_BASE64[$N] = ${VALIDATOR_PUB_KEY_BASE64[$N]}"

    pkill -9 ton_node &>/dev/null || true

    echo "      * done"
done

echo "INFO: preparing node configs... done"

echo "INFO: preparing zerostate..."

WEIGHT=10
TOTAL_WEIGHT=$(( $NODES * 2 ))
ZEROSTATE=$(sed "s/nowdate/$NOWDATE/g" "$RES_DIR/zero_state_blanc_1.json")
ZEROSTATE=$(echo "$ZEROSTATE" | sed "s/p34_total_weight/$NODES/g")
ZEROSTATE=$(echo "$ZEROSTATE" | sed "s/p34_total/$NODES/g")
echo "$ZEROSTATE" > "$TEMP_DIR/zero_state.json"

for (( N=0; N < $NODES; N++ ))
do
    echo "      * adding validator #$N"

    if [ $N -ne 0 ]; then
        printf ",\n" >> "$TEMP_DIR/zero_state.json"
    fi

    printf "{ \"public_key\": \"${VALIDATOR_PUB_KEY_HEX[$N]}\", \"weight\": \"$WEIGHT\"}" >> "$TEMP_DIR/zero_state.json"
done

cat "$RES_DIR/zero_state_blanc_2.json" >> "$TEMP_DIR/zero_state.json"

echo "      * generating states"

mkdir -p "$TEMP_DIR/zerostate"
pushd "$TEMP_DIR/zerostate" &>/dev/null
"$TOOLS_TARGET/zerostate" -i "$TEMP_DIR/zero_state.json"
popd > /dev/null

echo "INFO: preparing zerostate... done"

echo "INFO: generating global config..."

cat "$RES_DIR/ton-global.config_1.json" > "$TEMP_DIR/ton-global.config.json"

for (( N=0; N < $NODES; N++ ))
do
    echo "      * adding validator #$N"

    NODE_CONFIGS_DIR="$TEMP_DIR/node$N"

    if [ $N -ne 0 ]; then
        echo "," >> "$TEMP_DIR/ton-global.config.json"
    fi

    # DHT key is the first one in config (tag 1)
    KEYTAG=$(grep "pvt_key" "$NODE_CONFIGS_DIR/config.json" | head -n1 | cut -c 23-66)

    PORT=$(( 3000 + $N ))
    "$TOOLS_TARGET/gendht" $NOWIP:$PORT $KEYTAG >> "$TEMP_DIR/ton-global.config.json"
done

cat "$RES_DIR/ton-global.config_2.json" >> "$TEMP_DIR/ton-global.config.json"
GLOBAL_CONFIG=$(jq ".validator.zero_state = $(jq .zero_state "$TEMP_DIR/zerostate/config.json")" "$TEMP_DIR/ton-global.config.json")

# Looks like jq contains bug which converts big number wrong way, rolling back:
echo "$GLOBAL_CONFIG" | sed "s/-9223372036854776000/-9223372036854775808/g" > "$TEMP_DIR/ton-global.config.json"

echo "INFO: generating global config... done"

echo "INFO: starting nodes..."

for (( N=0; N < $NODES; N++ ))
do
    echo "      * starting node #$N"

    NODE_CONFIGS_DIR="$TEMP_DIR/node$N"

    cp "$TEMP_DIR/ton-global.config.json" "$NODE_CONFIGS_DIR/ton-global.config.json"

    pushd "$NODE_CONFIGS_DIR" > /dev/null
    "$NODE_TARGET/ton_node" --configs "$NODE_CONFIGS_DIR" -z "$TEMP_DIR/zerostate" >> "${LOGS_DIR}/node_$N.output" 2>&1 &
    popd > /dev/null
done

echo "INFO: starting nodes... done"
date
