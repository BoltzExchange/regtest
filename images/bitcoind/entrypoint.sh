#!/bin/bash

cleanup() {
    echo 'SIGINT or SIGTERM received, exiting'
    exit 0
}
trap cleanup SIGINT SIGTERM

# Start bitcoind in the background
bitcoind -regtest -fallbackfee=0.00000253 -zmqpubrawtx=tcp://0.0.0.0:29000 -zmqpubrawblock=tcp://0.0.0.0:29001 -txindex -rpcallowip=0.0.0.0/0 -rpcbind=0.0.0.0 &
BITCOIND_PID=$!

# Wait until bitcoind is ready
while true; do
    sleep 1
    if bitcoin-cli --rpccookiefile=/root/.bitcoin/regtest/.cookie -regtest getblockchaininfo &> /dev/null; then
        echo "bitcoind is ready"
        break
    else
        echo "Waiting for bitcoind to initialize..."
    fi
done

bitcoin-cli --rpccookiefile=/root/.bitcoin/regtest/.cookie -regtest createwallet regtest || bitcoin-cli --rpccookiefile=/root/.bitcoin/regtest/.cookie -regtest loadwallet regtest
# Generate 150 blocks
bitcoin-cli --rpccookiefile=/root/.bitcoin/regtest/.cookie -regtest -generate 150

if [ $? -eq 0 ]; then
    echo "Successfully generated blocks"
else
    echo "Failed to generate blocks"
fi



wait $BITCOIND_PID
