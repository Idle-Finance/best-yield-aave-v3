# Ethereum Smart Contract Template

https://docs.idle.finance/developers/best-yield/
https://github.com/aave/aave-v3-core
https://docs.aave.com/developers/getting-started/v3-overview

## Set up

It requires [Foundry](https://github.com/gakonst/foundry) installed to run. You can find instructions here [Foundry installation](https://github.com/gakonst/foundry#installation).

For Foundry specific features, refer to:

-   [repository](https://github.com/gakonst/foundry)
-   [cheat codes](https://github.com/gakonst/foundry/tree/master/forge#cheat-codes)
-   [Foundry book](https://onbjerg.github.io/foundry-book/index.html)

To set up type:

```bash
`make setup`
```

## Commands

-   `make setup` - initialize libraries and yarn packages
-   `make build` - build your project
-   `make xclean` - remove compiled files
-   `make lint` - lint files
-   [`make test`](#testing) - run tests
-   `make test-gasreport` - run tests and show gas report
-   `make watch` - watch files and re-run tests

## Testing

To run test type:

```sh
make test
```

### Testing forked chain

Work in progress...

<!-- ### Testing forked chain

You can also fork a chain by providing an RPC url to something like [Alchemy](https://www.alchemy.com/) or [Infura](https://infura.io/).

To enable blockchain forking, you need to copy `.env.example` to `.env` and change `RPC_ON` and `ETH_NODE` to match your environment.

```sh
export RPC_ON=yes
export ETH_NODE=https://eth-mainnet.alchemyapi.io/v2/ALCHEMY_API_KEY
```

After adding the variables to your `.env` you can run `make test` normally

You need to add the RPC url to your GitHub secrets as `ETH_NODE` to enable fork testing in GitHub Actions. Also make sure to uncomment these lines in [`.github/workflows/ci.yml`](.github/workflows/ci.yml).

```yaml
# Enable this if using forking tests
env:
    ETH_NODE: ${{ secrets.ETH_NODE }}
    RPC_ON: yes
``` -->

<!-- ## FAQ -->
