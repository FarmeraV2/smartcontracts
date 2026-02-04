-include .env

build:; forge build

# deploy-sepolia:
# 	forge script script/DeployProcessTracking.s.sol --rpc-url $(SEPOLIA_RPC_URL) --private-key $(WALLET_PRIVATE_KEY) --broadcast --etherscan-api-key $(API_KEY)

deploy:
	forge script script/DeployTrustComputation.s.sol --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY) --broadcast

get-record:
	cast call 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9 "getTrustRecord(uint64)" 25 --rpc-url $(RPC_URL)

decode-record:
	cast decode-abi "getTrustRecord(uint64)(uint64, uint256, uint256)" 0x000000000000000000000000000000000000000000000000000000000000001900000000000000000000000000000000000000000000000000000000000000460000000000000000000000000000000000000000000000000000000069837f07
