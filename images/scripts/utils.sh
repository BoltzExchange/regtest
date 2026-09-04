#!/usr/bin/env bash
BITCOIN_CLI_PARAMS="-rpcconnect=bitcoind -regtest -rpccookiefile=/root/.bitcoin/regtest/.cookie"

function bitcoin-cli-sim() {
  bitcoin-cli $BITCOIN_CLI_PARAMS "$@"
}

function bitcoin-cli-sim-server() {
  bitcoin-cli $BITCOIN_CLI_PARAMS -rpcwallet="regtest" "$@"
}

function bitcoin-cli-sim-client() {
  bitcoin-cli $BITCOIN_CLI_PARAMS -rpcwallet="client" "$@"
}

ELEMENTS_CLI_PARAMS="-rpcconnect=elementsd"
function elements-cli-sim() {
  elements-cli $ELEMENTS_CLI_PARAMS "$@"
}

function elements-cli-sim-server() {
  elements-cli $ELEMENTS_CLI_PARAMS -rpcwallet="regtest" "$@"
}

function elements-cli-sim-client() {
  elements-cli $ELEMENTS_CLI_PARAMS -rpcwallet="client" "$@"
}

#backwards compat
boltzcli-sim() {
  boltzcli --datadir=/root/.boltz-client --host boltz-client "$@"
}

boltz-client-cli-sim() {
  boltzcli-sim "$@"
}

# args(i, cmd)
lightning-cli-sim() {
  i=$1
  shift # shift first argument so we can use $@
  lightning-cli --network regtest --lightning-dir=/root/.lightning-"$i" "$@"
}

# args(i, cmd)
lncli-sim() {
  i=$1
  shift # shift first argument so we can use $@
  lncli --network regtest --rpcserver=lnd-$i:10009 --lnddir=/root/.lnd-"$i" "$@"
}

# client/backend convenience wrappers
lightning-cli-sim-client() {
  lightning-cli-sim 1 "$@"
}

lightning-cli-sim-server() {
  lightning-cli-sim 2 "$@"
}

lncli-sim-client() {
  lncli-sim 1 "$@"
}

lncli-sim-server() {
  lncli-sim 2 "$@"
}

# args(i)
fund_cln_node() {
  address=$(lightning-cli-sim $1 newaddr | jq -r .p2tr)
  echo "funding: $address on cln-node: $1"
  bitcoin-cli-sim-server -named sendtoaddress address=$address amount=30 fee_rate=1 > /dev/null
}

# args(i)
fund_lnd_node() {
  address=$(lncli-sim $1 newaddress p2wkh | jq -r .address)
  echo "funding: $address on lnd-node: $1"
  bitcoin-cli-sim-server -named sendtoaddress address=$address amount=30 fee_rate=1 > /dev/null
}

# args(i, j)
connect_cln_node() {
  pubkey=$(lightning-cli-sim $2 getinfo | jq -r '.id')
  lightning-cli-sim $1 connect $pubkey@cln-$2:9735 | jq -r '.id'
}

bitcoind-init() {
  # Wait until bitcoind is ready
  while true; do
      sleep 1
      if bitcoin-cli-sim-server getblockchaininfo &> /dev/null; then
          echo "bitcoind is ready"
          break
      else
          echo "Waiting for bitcoind to initialize..."
      fi
  done

  bitcoin-cli-sim createwallet regtest || bitcoin-cli-sim loadwallet regtest
  # Generate 150 blocks
  bitcoin-cli-sim-server -generate 150

  if [ $? -eq 0 ]; then
      echo "Successfully generated blocks"
  else
      echo "Failed to generate blocks"
  fi

  bitcoin-cli-sim createwallet client || bitcoin-cli-sim loadwallet client

  CLIENT_ADDRESS=$(bitcoin-cli-sim-client getnewaddress "" bech32m)
  bitcoin-cli-sim-server -rpcwallet=regtest sendtoaddress $CLIENT_ADDRESS 10
  bitcoin-cli-sim-server -rpcwallet=regtest -generate 1
}

# Needed for hold plugin to get the hooks first
restart_offer_plugin() {
    lightning-cli-sim $1 plugin stop /usr/libexec/c-lightning/plugins/offers
    lightning-cli-sim $1 plugin start /usr/libexec/c-lightning/plugins/offers
}

regtest-start(){
  restart_offer_plugin 1
  restart_offer_plugin 2

  regtest-init
}

elements-init(){
  elements-cli-sim createwallet regtest || elements-cli-sim loadwallet regtest true
  echo "mining 150 liquid blocks..."
  elements-cli-sim-server -generate 150 > /dev/null
  elements-cli-sim-server rescanblockchain 0 > /dev/null

  elements-cli-sim createwallet client || elements-cli-sim loadwallet client true

  CLIENT_ADDRESS=$(elements-cli-sim -rpcwallet=client getnewaddress)
  elements-cli-sim-server -rpcwallet=regtest sendtoaddress $CLIENT_ADDRESS 10

  # First wpkh_slip77 address of "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
  elements-cli-sim-server -rpcwallet=regtest sendtoaddress el1qq2xvpcvfup5j8zscjq05u2wxxjcyewk7979f3mmz5l7uw5pqmx6xf5xy50hsn6vhkm5euwt72x878eq6zxx2z0z676mna6kdq 10

  elements-cli-sim-server -rpcwallet=regtest -generate 1
}

regtest-init(){
  elements-init
  lightning-sync
  lightning-init
}

lightning-sync(){
  wait-for-cln-sync 1
  wait-for-cln-sync 2
  wait-for-lnd-sync 1
  wait-for-lnd-sync 2
  wait-for-lnd-sync 3
}

lightning-init(){
  # create 10 UTXOs for each node
  for i in 0 1 2 3 4; do
    fund_cln_node 1
    fund_cln_node 2
    fund_lnd_node 1
    fund_lnd_node 2
    fund_lnd_node 3
  done

  echo "mining 3 blocks..."
  bitcoin-cli-sim-server -generate 3 > /dev/null

  lightning-sync

  channel_confirms=6
  channel_size=24000000 # 0.024 btc
  balance_size=12000000 # 0.12 btc
  balance_size_msat=12000000000 # 0.12 btc

  # lnd-1 -> lnd-2
  lncli-sim 1 connect $(lncli-sim 2 getinfo | jq -r '.identity_pubkey')@lnd-2 > /dev/null
  echo "open channel from lnd-1 to lnd-2"
  lncli-sim 1 openchannel $(lncli-sim 2 getinfo | jq -r '.identity_pubkey') $channel_size $balance_size > /dev/null
  bitcoin-cli-sim-server -generate $channel_confirms > /dev/null
  wait-for-lnd-channel 1
  lightning-sync

  # lnd-1 -> cln-1
  lncli-sim 1 connect $(lightning-cli-sim 1 getinfo | jq -r '.id')@cln-1 > /dev/null
  echo "open channel from lnd-1 to cln-1"
  lncli-sim 1 openchannel $(lightning-cli-sim 1 getinfo | jq -r '.id') $channel_size $balance_size > /dev/null
  bitcoin-cli-sim-server -generate $channel_confirms > /dev/null
  wait-for-lnd-channel 1
  lightning-sync

  # lnd-2 -> cln-1
  lncli-sim 2 connect $(lightning-cli-sim 1 getinfo | jq -r '.id')@cln-1 > /dev/null
  echo "open channel from lnd-2 to cln-1"
  lncli-sim 2 openchannel $(lightning-cli-sim 1 getinfo | jq -r '.id') $channel_size $balance_size > /dev/null
  bitcoin-cli-sim-server -generate $channel_confirms > /dev/null
  wait-for-lnd-channel 2
  wait-for-cln-channel 1
  lightning-sync

  # lnd-1 -> cln-2
  lncli-sim 1 connect $(lightning-cli-sim 2 getinfo | jq -r '.id')@cln-2 > /dev/null
  echo "open channel from lnd-1 to cln-2"
  lncli-sim 1 openchannel $(lightning-cli-sim 2 getinfo | jq -r '.id') $channel_size $balance_size > /dev/null
  bitcoin-cli-sim-server -generate $channel_confirms > /dev/null
  wait-for-lnd-channel 1
  wait-for-cln-channel 2
  lightning-sync

  # lnd-2 -> cln-2
  lncli-sim 2 connect $(lightning-cli-sim 2 getinfo | jq -r '.id')@cln-2 > /dev/null
  echo "open channel from lnd-2 to cln-2"
  lncli-sim 2 openchannel $(lightning-cli-sim 2 getinfo | jq -r '.id') $channel_size $balance_size > /dev/null
  bitcoin-cli-sim-server -generate $channel_confirms > /dev/null
  wait-for-lnd-channel 2
  wait-for-cln-channel 2

  # cln-1 -> cln-2 P2P connection for offer fetching
  lightning-cli-sim 1 connect $(lightning-cli-sim 2 getinfo | jq -r '.id')@cln-2:9735

  lightning-sync

  # lnd-3 -> lnd-1 (for routing through client network)
  lncli-sim 3 connect $(lncli-sim 1 getinfo | jq -r '.identity_pubkey')@lnd-1 > /dev/null
  echo "open channel from lnd-3 to lnd-1"
  lncli-sim 3 openchannel $(lncli-sim 1 getinfo | jq -r '.identity_pubkey') $channel_size $balance_size > /dev/null
  bitcoin-cli-sim-server -generate $channel_confirms > /dev/null
  wait-for-lnd-channel 3
  lightning-sync

  # lnd-3 -> cln-1
  lncli-sim 3 connect $(lightning-cli-sim 1 getinfo | jq -r '.id')@cln-1 > /dev/null
  echo "open channel from lnd-3 to cln-1"
  lncli-sim 3 openchannel $(lightning-cli-sim 1 getinfo | jq -r '.id') $channel_size $balance_size > /dev/null
  bitcoin-cli-sim-server -generate $channel_confirms > /dev/null
  wait-for-lnd-channel 3
  wait-for-cln-channel 1
  lightning-sync

  # lnd-3 -> cln-2
  lncli-sim 3 connect $(lightning-cli-sim 2 getinfo | jq -r '.id')@cln-2 > /dev/null
  echo "open channel from lnd-3 to cln-2"
  lncli-sim 3 openchannel $(lightning-cli-sim 2 getinfo | jq -r '.id') $channel_size $balance_size > /dev/null
  bitcoin-cli-sim-server -generate $channel_confirms > /dev/null
  wait-for-lnd-channel 3
  wait-for-cln-channel 2
  lightning-sync

}

wait-for-lnd-channel(){
  while true; do
    pending=$(lncli-sim $1 pendingchannels | jq -r '.pending_open_channels | length')
    echo "lnd-$1 pendingchannels: $pending"
    if [[ "$pending" == "0" ]]; then
      break
    fi
    sleep 1
  done
}

wait-for-lnd-sync(){
  while true; do
    if [[ "$(lncli-sim $1 getinfo 2>&1 | jq -r '.synced_to_chain' 2> /dev/null)" == "true" ]]; then
      echo "lnd-$1 is synced!"
      break
    fi
    echo "waiting for lnd-$1 to sync..."
    sleep 1
  done
}

wait-for-cln-channel(){
  while true; do
    pending=$(lightning-cli-sim $1 getinfo | jq -r '.num_pending_channels | length')
    echo "cln-$1 pendingchannels: $pending"
    if [[ "$pending" == "0" ]]; then
      if [[ "$(lightning-cli-sim $1 getinfo 2>&1 | jq -r '.warning_bitcoind_sync' 2> /dev/null)" == "null" ]]; then
        if [[ "$(lightning-cli-sim $1 getinfo 2>&1 | jq -r '.warning_lightningd_sync' 2> /dev/null)" == "null" ]]; then
          break
        fi
      fi
    fi
    sleep 1
  done
}

wait-for-cln-sync(){
  while true; do
    if [[ "$(lightning-cli-sim $1 getinfo 2>&1 | jq -r '.warning_bitcoind_sync' 2> /dev/null)" == "null" ]]; then
      if [[ "$(lightning-cli-sim $1 getinfo 2>&1 | jq -r '.warning_lightningd_sync' 2> /dev/null)" == "null" ]]; then
        echo "cln-$1 is synced!"
        break
      fi
    fi
    echo "waiting for cln-$1 to sync..."
    sleep 1
  done
}

# Deploy contracts

