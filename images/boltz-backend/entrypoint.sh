#!/bin/sh
set -eu

exec node --trace-deprecation /boltz-backend/bin/boltzd \
  --datadir /boltz-data \
  --configpath /boltz-data/boltz.conf
