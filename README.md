# Boltz Regtest

Successor of [legend-regtest-enviroment](https://github.com/BoltzExchange/legend-regtest-enviroment)

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
- boltzcli-sim
- lightning-cli-sim
- lncli-sim

Sinds there will be running 2 lnd and cln instances, please use `lightning-cli-sim 1` to call an instance. Both `1` and `2` are available for lnd and cln.

Or alternatively, you can `source aliases.sh` to have these convenience scripts available on the host machine.

### Block explorers

[Esplora](https://github.com/Blockstream/esplora) is running for the Bitcoin Core and Elements regtest:

- Bitcoin: [http://localhost:4002](http://localhost:4002)
- Elements: [http://localhost:4003](http://localhost:4003)

[Otterscan](https://github.com/otterscan/otterscan) is used as block explorer for Anvil: [http://localhost:5100](http://localhost:5100)
