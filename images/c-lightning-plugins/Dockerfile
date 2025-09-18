ARG VERSION=latest
ARG UBUNTU_VERSION=24.04

FROM ubuntu:${UBUNTU_VERSION} AS build

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

RUN git clone --depth 1 --branch v0.3.2 https://github.com/BoltzExchange/hold.git /hold
WORKDIR /hold
RUN cargo build --release

FROM boltz/c-lightning:${VERSION} AS builder

RUN apt-get update && apt-get install -y git pkg-config wget

WORKDIR /clnurl

# TODO: download arm artifacts
RUN wget https://github.com/michael1011/clnurl/releases/download/v0.1.0/clnurl.tar.gz
RUN tar -xvf clnurl.tar.gz

FROM boltz/c-lightning:${VERSION}

COPY --from=build /hold/target/release/hold /usr/local/bin/hold
COPY --from=builder /clnurl/clnurl /usr/local/bin/clnurl

ENTRYPOINT ["lightningd"]
