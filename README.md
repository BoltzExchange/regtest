# Boltz Regtest

Successor of [legend-regtest-enviroment](https://github.com/BoltzExchange/legend-regtest-enviroment)

## Usage
```
./start.sh
```

```
./stop.sh
```

Data dirs for the services are stored in `./data` folder.

### Scripts container

```
docker exec -it boltz-scripts bash
```

- bitcoin-cli-sim
- elements-cli-sim
- boltzcli-sim
- lightning-cli-sim
- lncli-sim

Or alternatively, you can `source aliases.sh` to have these convenience scripts available on the host machine.

### Block explorers

[Esplora](https://github.com/Blockstream/esplora) is running for the Bitcoin Core and Elements regtest:

- Bitcoin: [http://localhost:4002](http://localhost:4002)
- Elements: [http://localhost:4003](http://localhost:4003)
