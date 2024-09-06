ARG NODE_VERSION=lts-bookworm-slim

FROM node:${NODE_VERSION} AS builder

RUN git clone https://github.com/rsksmart/rif-relay-contracts.git

WORKDIR /rif-relay-contracts

RUN git checkout ccdfb99f93ba35b8e8e53ab6050311029cbe668e
COPY contracts.patch .
RUN git apply contracts.patch

RUN npm ci

WORKDIR /
RUN git clone https://github.com/rsksmart/rif-relay-server.git

WORKDIR /rif-relay-server

RUN git checkout 723893cc3e3bf2ee9fc9f9130fb03ba45ae150ee
COPY server.patch .
RUN git apply server.patch

RUN npm ci

COPY start.sh /

ENTRYPOINT ["/bin/bash", "/start.sh"]
