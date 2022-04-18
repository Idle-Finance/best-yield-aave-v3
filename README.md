# Aave V3 wrapper for Idle Best Yield

## Set up

It requires [Foundry](https://github.com/gakonst/foundry) installed to run. You can find instructions here [Foundry installation](https://github.com/gakonst/foundry#installation).

For Foundry specific features, refer to:

-   [repository](https://github.com/gakonst/foundry)
-   [cheat codes](https://github.com/gakonst/foundry/tree/master/forge#cheat-codes)
-   [Foundry book](https://onbjerg.github.io/foundry-book/index.html)

To set up type:

```bash
make setup
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

To run test on local network type:

```sh
make test
```

To run test on forked polygon network, copy `.env.example` to `.env` and set the following environment variables.

```sh
export ALCHEMY_API_KEY=YOUR_API_KEY
export POLYGON_RPC_URL=https://polygon-mainnet.g.alchemy.com/v2/${ALCHEMY_API_KEY}
export FORK_BLOCK_NUMBER=26900000 # polygon

```

then Type:

```sh
make test-fork
```

## Docs

[Idle Finance docs](https://docs.idle.finance/developers/best-yield/)

[GitHub aave-v3-core](https://github.com/aave/aave-v3-core)

[Aave V3 docs](https://docs.aave.com/developers/getting-started/v3-overview)
