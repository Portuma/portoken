# Por Token Smart Contracts

**First In-Game Ad Token On Blockchain**

- [Project Home Page](https://portoken.com)
- Designed for Solidity >=0.8.4
- uses OpenZeppelin UUPS proxy standart
- Complementary to [OpenZeppelin Contracts Upgradeable](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable)
- Tests with Hardhat and Waffle
- Managed with OpenZeppelin Defender
- Ownership will be transferred to [Gnosis Multisig Wallet](https://gnosis-safe.io/)

## Installation

With npm:

```sh
git clone git@github.com:Portuma/portoken.git
```

### Pre Requisites

Before running any command, make sure to install dependencies:

```sh
$ npm install
```

Configure environments
```sh
$ cp env.dist .env
```

### Compile

Compile the smart contracts with Hardhat:

```sh
$ npx hardhat compile
```

### Test

Run the Mocha tests:

```sh
$ npm test
```

## License

The contracts are released under the [MIT License](./LICENSE.md).

#
#### Smart Contracts Developed by [WeCare Labs](https://wecarelabs.org)