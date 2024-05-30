#!/bin/bash
set -xe

cleanup() {
    echo 'SIGINT or SIGTERM received, exiting'
    exit 0
}

cp /root/.bitcoin/regtest/.cookie /root/.host-data/.bitcoind-cookie
# TODO: copy over everything we need for the host

trap cleanup SIGINT SIGTERM
sleep infinity &
wait