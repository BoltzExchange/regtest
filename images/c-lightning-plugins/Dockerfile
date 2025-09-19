ARG VERSION=latest
ARG UBUNTU_VERSION=24.04

FROM ubuntu:${UBUNTU_VERSION} AS build

ARG HOLD_VERSION=v0.3.2

RUN apt-get update && apt-get -y upgrade
RUN apt-get -y install \
    gcc \
    git \
    curl \
    libpq-dev \
    libsqlite3-dev \
    protobuf-compiler

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

RUN git clone --depth 1 --branch ${HOLD_VERSION} https://github.com/BoltzExchange/hold.git /hold
WORKDIR /hold
RUN cargo build --release

FROM boltz/c-lightning:${VERSION} AS builder

ARG CLNURL_VERSION=v0.1.0

RUN apt-get update && apt-get install -y git pkg-config wget

WORKDIR /clnurl

# Download the correct clnurl artifact based on architecture
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then \
        wget https://github.com/michael1011/clnurl/releases/download/${CLNURL_VERSION}/clnurl.tar.gz; \
    else \
        wget https://github.com/michael1011/clnurl/releases/download/${CLNURL_VERSION}/clnurl-arm64.tar.gz -O clnurl.tar.gz; \
    fi

RUN tar -xvf clnurl.tar.gz

FROM boltz/c-lightning:${VERSION}

COPY --from=build /hold/target/release/hold /usr/local/bin/hold
COPY --from=builder /clnurl/clnurl /usr/local/bin/clnurl

ENTRYPOINT ["lightningd"]
