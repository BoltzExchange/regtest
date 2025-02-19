# Boltz Regtest

An environment for local development and testing, successor of [legend-regtest-enviroment](https://github.com/BoltzExchange/legend-regtest-enviroment).

## Prerequisites
[Docker](https://docs.docker.com/engine/install/) or [Orbstack](https://orbstack.dev/) for Apple Silicon based Macs.
When using OrbStack on macOS, set `export DOCKER_DEFAULT_PLATFORM=linux/amd64` before starting.

## Usage

```bash
./start.sh
```

```bash
./stop.sh
```

- Web App: [http://localhost:8080](http://localhost:8080)

Data dirs for the services are stored in `./data` folder.

### Scripts container

```bash
docker exec -it boltz-scripts bash
```

- bitcoin-cli-sim-client
- bitcoin-cli-sim-server
- elements-cli-sim-client
- elements-cli-sim-server
- boltzcli-sim ([boltz-client](https://github.com/BoltzExchange/boltz-client))
- lightning-cli-sim
- lncli-sim

Since there are two lnd and two cln instances, use `lncli-sim 1` or `lightning-cli-sim 1` to interact with the first instance and `lncli-sim 2` or `lightning-cli-sim 2` to interact with the second.

Or alternatively, you can `source aliases.sh` to have these convenience scripts available on the host machine.

### Block explorers

[Esplora](https://github.com/Blockstream/esplora) is running for the Bitcoin Core and Elements regtest:

- Bitcoin: [http://localhost:4002](http://localhost:4002)
- Elements: [http://localhost:4003](http://localhost:4003)

[Otterscan](https://github.com/otterscan/otterscan) is used as block explorer for Anvil: [http://localhost:5100](http://localhost:5100)
