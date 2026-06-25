#!/bin/sh
set -eu

# Wrapper entrypoint for the Boltz backend.
#
# The Arbitrum stack (the `anvil-arb` node and the `[arbitrum]` config section)
# is opt-in: it only runs under the `ci`, `backend-dev` and `webapp-ci` compose
# profiles, not under `default`. So the backend must not require an Arbitrum
# node when running the default stack.
#
# `anvil-arb` is a soft healthy dependency of this service, so by the time this
# runs it is reachable exactly when it is part of the active profiles. We use
# that to decide whether to append the Arbitrum config section to the base
# config the backend reads.

CONFIG="/boltz-data/boltz.conf"

if getent hosts anvil-arb > /dev/null 2>&1; then
  # Assemble in /boltz-data (next to the base config), NOT /tmp: the sidecar
  # resolves the mnemonic (seed.dat) relative to the config file's directory.
  CONFIG="/boltz-data/boltz.runtime.conf"
  { cat /boltz-data/boltz.conf; echo; cat /arbitrum.conf; } > "$CONFIG"
fi

# Mirrors the ENTRYPOINT of the boltz/boltz image.
exec node --trace-deprecation /boltz-backend/bin/boltzd \
  --datadir /boltz-data \
  --configpath "$CONFIG"
