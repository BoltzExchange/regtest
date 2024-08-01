#!/bin/bash

cleanup() {
    echo 'SIGINT or SIGTERM received, exiting'
    exit 0
}

trap cleanup SIGINT SIGTERM

register_relay() {
    # We can sleep for a while; this can happen in the background
    sleep 15
    cd /rif-relay-server
    npm run register
}

cd /rif-relay-contracts
npx hardhat deploy --network regtest

cd /rif-relay-server

register_relay &
npm run start &

wait
