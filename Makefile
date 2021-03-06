# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# Update dependencies
setup			:; make update-libs ; make install-deps
update-libs		:; git submodule update --init --recursive
install-deps	:; yarn install --frozen-lockfile

# Build & test & deploy
build         	:; forge build
xclean        	:; forge clean
lint          	:; yarn run lint
test          	:; forge test ${VERBOSITY_OPTION} 
test-gasreport 	:; forge test --gas-report
test-fork       :; forge test ${VERBOSITY_OPTION} --fork-url ${POLYGON_RPC_URL} --fork-block-number ${FORK_BLOCK_NUMBER}
watch		  	:; forge test --watch src/
