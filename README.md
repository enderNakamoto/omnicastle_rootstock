# Omicastle on AirDao
## Quickstart

To get started with Scaffold-ETH 2, follow the steps below:

1. Install dependencies 

```
yarn install
```

2. Run a local network in the first terminal:

```
yarn chain
```

This command starts a local Ethereum network using Foundry. The network runs on your local machine and can be used for testing and development. You can customize the network configuration in `packages/foundry/foundry.toml`.

```
evm_version = "Istanbul"

[rpc_endpoints]
airDaoDevnet = "https://network.ambrosus-dev.io/"
airDaoTestnet = "https://network.ambrosus-test.io"
airDaoMainnet = "https://network.ambrosus.io"

```

3. On a second terminal, deploy the test contract:

```
yarn deploy
```

4. Run smart contract test with `yarn foundry:test`

There's full unit test coverage for the smart contract: 
![alt text](image.png)

5. Deploying on testnet 

Deploy and verify together:
```
forge script -f <devnet|testnet|mainnet> --private-key <YOUR_PRIVATE_KEY> --legacy --broadcast --verifier sourcify --verifier-url https://sourcify.ambrosus.io/ --verify CounterScript
```

for scaffold-eth:

```
yarn deploy --network network_name
```
Therefore, to deploy on airdaoTestnet:
```
yarn deploy --network airdaoTestnet
```

Deployed at: 0xCD05229f4D382c0C8dA75c83011E55299EeA6b2b



