FROM rust:latest AS builder

RUN apt-get update && apt-get install -y git clang libclang-dev

RUN git clone https://github.com/blockstream/electrs && \
    cd electrs && \
    git checkout new-index

WORKDIR /electrs

RUN cargo build --release --bin electrs
RUN cp /electrs/target/release/electrs electrs-bitcoin
RUN cargo build --features liquid --release --bin electrs

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y curl && \
    apt-get clean all && rm -rf /var/lib/apt/lists/*

COPY --from=builder /electrs/electrs-bitcoin /usr/local/bin/electrs-bitcoin
COPY --from=builder /electrs/target/release/electrs /usr/local/bin/electrs-liquid

ENTRYPOINT ["electrs-bitcoin", "-vvvv", "--daemon-dir", "/root/.bitcoin"]
