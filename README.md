# boltz-docker

Based on [legend-regtest-enviroment](https://github.com/BoltzExchange/legend-regtest-enviroment)

## Usage
```
./start.sh
```

Auth credentials for the host are stored in `./data/host` folder.

### Scripts container

```
docker exec -it boltz-scripts bash
```

- bitcoin-cli-sim
- elements-cli-sim
- boltzcli-sim
- lightning-cli-sim
- lncli-sim
