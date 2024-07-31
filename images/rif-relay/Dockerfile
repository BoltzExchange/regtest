ARG NODE_VERSION=lts-bookworm-slim

FROM node:${NODE_VERSION} AS builder

RUN git clone https://github.com/rsksmart/rif-relay-contracts.git

WORKDIR /rif-relay-contracts

RUN git checkout 59b67d6ccd901f8e2320e3aea5a5fc937956f34b
COPY contracts.patch .
RUN git apply contracts.patch

RUN npm ci

WORKDIR /
RUN git clone https://github.com/rsksmart/rif-relay-server.git

WORKDIR /rif-relay-server

RUN git checkout a4807e557d8205ab285b8891cef58e8b5fb2994a
COPY server.patch .
RUN git apply server.patch

RUN npm ci

COPY start.sh /

ENTRYPOINT ["/bin/bash", "/start.sh"]
