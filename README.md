# Por Token Smart Contracts

**First In-Game Ad Token On Blockchain**

- [Project Home Page](https://portoken.com)
- Designed for Solidity = 0.8.4
- uses OpenZeppelin Transparent proxy standart
- Complementary to [OpenZeppelin Contracts Upgradeable](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable)
- Tests with Hardhat and Waffle
- Managed with OpenZeppelin Defender
- Contract Ownership transferred to [Timelock Controller](https://bscscan.com/address/0x3E69224929B1dE44dD7CF4797eeC7D51E3341e3d)
- Timelock Controller has only one proposer, which is [Gnosis Multisig Wallet](https://bscscan.com/address/0xd180f598c281a1B6AEa81Fc7A1268017a7D1EF5E)
- Timelock Controller Ownership is renounced to Timelock Controller itself

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