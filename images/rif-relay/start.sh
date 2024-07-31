#!/bin/bash

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
npm run start
