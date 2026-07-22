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

# Assemble in /boltz-data (next to the base config), NOT /tmp: the sidecar
# resolves the mnemonic (seed.dat) relative to the config file's directory.
append_config() {
  if [ "$CONFIG" = "/boltz-data/boltz.conf" ]; then
    CONFIG="/boltz-data/boltz.runtime.conf"
    cat /boltz-data/boltz.conf > "$CONFIG"
  fi
  { echo; cat "$1"; } >> "$CONFIG"
}

if getent hosts anvil-arb > /dev/null 2>&1; then
  append_config /arbitrum.conf
fi

# The Ark stack is opt-in via the `ark` and `backend-dev` profiles. Unlike
# anvil-arb, fulmine is not a dependency of this service: the readiness
# guarantee is transitive. This service starts after regtest-start completes,
# and regtest-init — keyed on the COMPOSE_PROFILES env var, which start.sh
# passes through — blocks on fulmine's API and on its admin macaroon existing
# (fulmine-init) before completing. So when fulmine resolves here, the
# macaroon referenced by ark.conf is already on the shared volume.
if getent hosts fulmine > /dev/null 2>&1; then
  append_config /ark.conf
fi

# Mirrors the ENTRYPOINT of the boltz/boltz image.
exec node --trace-deprecation /boltz-backend/bin/boltzd \
  --datadir /boltz-data \
  --configpath "$CONFIG"
