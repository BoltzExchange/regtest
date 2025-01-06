ARG VERSION=latest

FROM boltz/c-lightning:${VERSION} AS builder

RUN apt-get update && apt-get install -y git pkg-config wget

WORKDIR /hold

# TODO: download arm artifacts
RUN wget https://github.com/BoltzExchange/hold/releases/download/v0.2.0/hold-linux-amd64.tar.gz
RUN tar -xvf hold-linux-amd64.tar.gz

WORKDIR /clnurl

RUN wget https://github.com/michael1011/clnurl/releases/download/v0.1.0/clnurl.tar.gz
RUN tar -xvf clnurl.tar.gz

FROM boltz/c-lightning:${VERSION}

COPY --from=builder /hold/build/hold-linux-amd64 /root/hold
COPY --from=builder /clnurl/clnurl /root/clnurl

ENTRYPOINT ["lightningd"]
