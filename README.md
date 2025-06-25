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
- API: [http://localhost:9001](http://localhost:9001)


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

### Your first swap

Run `./start.sh`

then run bash on the container

```bash
docker exec -it boltz-scripts bash
```

check the boltz client bitcoin wallet balance

```bash
bitcoin-cli-sim-client getbalance
```

#### Connecting to the network

Your lightning node needs to connect to the boltz regtest network.

- RPC: connect to bitcoind via rpc (`127.0.0.1:18433`, using cookie auth or rpc user:password can be extracted with `cat /root/.bitcoin/regtest/.cookie`)
- Esplora: (`http://localhost:4002/api`)

#### Top up your wallet

Generate an address in your on-chain regtest wallet connected to your lightning node, and send 1 BTC e.g.

```bash
bitcoin-cli-sim-client sendtoaddress bcrt1qfzjp72mft2kcx49w49l5v6vdegr7lff86j08w7 1
```

Then mine a block for the transaction to confirm:

```bash
bitcoin-cli-sim-client -generate 1
```

#### Open a channel with LND-1

1. Get the identity_pubkey:

```bash
lncli-sim 1 getinfo
```

2. Connect to the peer: *replace the below identity pubkey with the identity_pubkey from above*

`023a6159c3be21ef992d89d9579c589c9f27308e61ae1dcb609170c13af09c0504@127.0.0.1:29735`

3. Open a channel (e.g. 500k sats)

4. Mine some blocks for the open channel transaction to confirm:

```bash
bitcoin-cli-sim-client -generate 6
```

#### Swapping out

Now that you have opened a channel and all the funds are on your side, you can swap out.

1. Visit the [Boltz Web App](http://localhost:8080) to initiate a swap
2. Providing an on-chain address from your on-chain regtest wallet connected to your lightning node
3. Use your lightning node to pay the lightning invoice provided by Boltz.
4. Make sure to mine a block for the swap to complete.

### Swapping in

After swapping out and you have some receiving capacity you can try swapping in to your channel.

1. Create an invoice from your lightning node
2. Paste it into the form
3. Pay the amount specified to the on-chain address.
4. Make sure to mine a block for the swap to complete.
