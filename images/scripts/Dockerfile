ARG UBUNTU_VERSION=24.04

FROM boltz/bitcoin-core:latest AS bitcoin-core
FROM ghcr.io/vulpemventures/elements:latest AS elements-core

FROM boltz/lnd:latest AS lnd
FROM boltz/c-lightning:latest AS cln

FROM boltz/foundry:latest AS anvil

FROM boltz/boltz-client:latest AS boltz-client

FROM ubuntu:${UBUNTU_VERSION}

RUN apt-get update && apt-get install -y bash jq libevent-dev
COPY --from=bitcoin-core /bin/bitcoin-cli /bin/
COPY --from=elements-core /usr/local/bin/elements-cli /bin/
COPY --from=lnd /bin/lncli /bin/
COPY --from=cln /bin/lightning-cli /bin/
COPY --from=anvil /root/.foundry/bin/cast /bin/
COPY --from=boltz-client /usr/bin/boltzcli /bin/

COPY utils.sh /etc/profile.d/utils.sh
RUN chmod +x /etc/profile.d/utils.sh

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY cleanup.sh /cleanup.sh
RUN chmod +x /cleanup.sh

RUN echo "if [ -f /etc/profile.d/utils.sh ]; then source /etc/profile.d/utils.sh; fi" >> /etc/bash.bashrc

ENTRYPOINT ["/entrypoint.sh"]
