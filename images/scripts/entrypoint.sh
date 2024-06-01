#!/bin/bash
set -xe

cleanup() {
    echo 'SIGINT or SIGTERM received, exiting'
    exit 0
}

cp /root/.bitcoin/regtest/.cookie /root/.host-data/.bitcoind-cookie
cp /root/.lnd-2/tls.cert /root/.host-data/lnd-2-tls.cert
cp /root/.lnd-2/data/chain/bitcoin/regtest/admin.macaroon /root/.host-data/lnd-2-admin.macaroon
cp /root/.lightning-1/regtest/ca.pem /root/.host-data/lightning-1-ca.pem
cp /root/.lightning-1/regtest/client-key.pem /root/.host-data/lightning-1-client-key.pem
cp /root/.lightning-1/regtest/client.pem /root/.host-data/lightning-1-client.pem
# TODO: copy over everything we need for the host

trap cleanup SIGINT SIGTERM
sleep infinity &
wait