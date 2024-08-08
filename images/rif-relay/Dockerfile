ARG NODE_VERSION=lts-bookworm-slim

FROM node:${NODE_VERSION} AS builder

RUN git clone https://github.com/rsksmart/rif-relay-contracts.git

WORKDIR /rif-relay-contracts

RUN git checkout d72976fd0834f034df1c3c6b068c95e5f6110d59
COPY contracts.patch .
RUN git apply contracts.patch

RUN npm ci

WORKDIR /
RUN git clone https://github.com/rsksmart/rif-relay-server.git

WORKDIR /rif-relay-server

RUN git checkout d26d46dfa732ada658c58d8c03282598753211c0
COPY server.patch .
RUN git apply server.patch

RUN npm ci

COPY start.sh /

ENTRYPOINT ["/bin/bash", "/start.sh"]
