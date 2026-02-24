-include .env

TRUST_COMPUTATION_ADDRESS = 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707

trust-deploy-sepolia:
	forge script script/DeployTrustComputation.s.sol --rpc-url $(SEPOLIA_RPC_URL) --private-key $(WALLET_PRIVATE_KEY) --broadcast --etherscan-api-key $(SEPOLIA_API_KEY) --verify

trust-deploy-anvil:
	forge script script/DeployTrustComputation.s.sol --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY) --broadcast

trust-deploy-zksync-anvil:
	forge script script/DeployTrustComputation.s.sol --rpc-url $(ZKSYNC_RPC_URL) --private-key $(PRIVATE_KEY) --legacy --zksync

trust-deploy-zksync-sepolia:
	forge script script/DeployTrustComputation.s.sol --rpc-url $(ZKSYNC_SEPOLIA_RPC_URL) --private-key $(WALLET_PRIVATE_KEY) --legacy --zksync

trust-get-record:
	cast call $(TRUST_COMPUTATION_ADDRESS) "getTrustRecord(bytes32, uint64)" $(BYTES32_IDENTIFIER) 1 --rpc-url $(RPC_URL)

trust-decode-record:
	cast decode-abi "getTrustRecord(bytes32, uint64)(bytes32, uint64, uint256, uint256)" 0x2de837825143d8db1af63ebd5afd9feb6080222abcbda49b2018d11215a33241000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
