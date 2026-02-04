-include .env

build:; forge build

# deploy-sepolia:
# 	forge script script/DeployProcessTracking.s.sol --rpc-url $(SEPOLIA_RPC_URL) --private-key $(WALLET_PRIVATE_KEY) --broadcast --etherscan-api-key $(API_KEY)

deploy:
	forge script script/DeployTrustComputation.s.sol --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY) --broadcast