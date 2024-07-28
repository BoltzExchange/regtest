#!/bin/bash

run_in_container() {
    docker exec -it boltz-scripts bash -c "source /etc/profile.d/utils.sh && $(printf '%q ' "$@")"
}

alias bitcoin-cli-sim='run_in_container bitcoin-cli-sim -rpcwallet=client'
alias elements-cli-sim='run_in_container elements-cli-sim -rpcwallet=client'
alias boltzcli-sim='run_in_container boltzcli-sim'

lightning-cli-sim() {
    run_in_container lightning-cli-sim "$@"
}

lncli-sim() {
    run_in_container lncli-sim "$@"
}
