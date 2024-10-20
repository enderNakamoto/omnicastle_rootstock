# Omicastle on AirDao
## Quickstart

```
yarn install
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

3. deploy the test contract:

Localchain:

```
yarn deploy
```

testnet:

```
yarn deploy --network airdaoTestnet
```
Deployed at: 0xCD05229f4D382c0C8dA75c83011E55299EeA6b2b

Transactions: https://testnet.airdao.io/explorer/address/0x1FC950ff4be0403f9ad51c9192AebbD617b72E4E/

4. Tests 

We have really good test coverage :

```
yarn foundry:test
```
![alt text](image.png)


## Project: 
