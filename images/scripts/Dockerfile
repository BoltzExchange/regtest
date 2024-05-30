FROM boltz/bitcoin-core:24.0.1 AS bitcoin-core
FROM ghcr.io/vulpemventures/elements:22.1.1 as elements-core

FROM boltz/lnd:0.17.0-beta as lnd
FROM boltz/c-lightning:23.08.1 as cln

FROM boltz/foundry:latest as anvil

FROM boltz/boltz-client:latest as boltz-client

FROM ubuntu:24.04

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

RUN echo "if [ -f /etc/profile.d/utils.sh ]; then source /etc/profile.d/utils.sh; fi" >> /etc/bash.bashrc

ENTRYPOINT ["/entrypoint.sh"]