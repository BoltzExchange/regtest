FROM node:20-bookworm-slim

WORKDIR /app

COPY package.json package.json
RUN npm install --no-audit --no-fund

COPY contracts contracts
COPY hardhat.config.js hardhat.config.js
COPY scripts scripts

RUN npx hardhat compile

ENTRYPOINT ["npx", "hardhat", "run", "--network", "regtest", "/app/scripts/deploy.js"]
