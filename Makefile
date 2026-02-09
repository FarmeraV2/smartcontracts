-include .env

build:; forge build

deploy-sepolia:
	forge script script/DeployTrustComputation.s.sol --rpc-url $(SEPOLIA_RPC_URL) --private-key $(WALLET_PRIVATE_KEY) --broadcast --etherscan-api-key $(SEPOLIA_API_KEY) --verify

deploy-anvil:
	forge script script/DeployTrustComputation.s.sol --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY) --broadcast

deploy-zksync-anvil:
		forge script script/DeployTrustComputation.s.sol --rpc-url $(ZKSYNC_RPC_URL) --private-key $(PRIVATE_KEY) --legacy --zksync

deploy-zksync-sepolia:
		forge script script/DeployTrustComputation.s.sol --rpc-url $(ZKSYNC_SEPOLIA_RPC_URL) --private-key $(WALLET_PRIVATE_KEY) --legacy --zksync

get-record:
	cast call 0x0165878A594ca255338adfa4d48449f69242Eb8F "getTrustRecord(bytes32, uint64)" 0x2de837825143d8db1af63ebd5afd9feb6080222abcbda49b2018d11215a33241 1 --rpc-url $(RPC_URL)

decode-record:
	cast decode-abi "getTrustRecord(bytes32, uint64)(bytes32, uint64, uint256, uint256)" 0x2de837825143d8db1af63ebd5afd9feb6080222abcbda49b2018d11215a33241000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
