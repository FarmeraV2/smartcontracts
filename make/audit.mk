audit-deploy-sepolia:
	forge script script/DeployAuditorRegistry.s.sol --rpc-url $(SEPOLIA_RPC_URL) --private-key $(WALLET_PRIVATE_KEY) --broadcast --etherscan-api-key $(SEPOLIA_API_KEY) --verify

audit-deploy-anvil:
	forge script script/DeployAuditorRegistry.s.sol --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY) --broadcast

audit-deploy-zksync-anvil:
	forge script script/DeployAuditorRegistry.s.sol --rpc-url $(ZKSYNC_RPC_URL) --private-key $(PRIVATE_KEY) --legacy --zksync

audit-deploy-zksync-sepolia:
	forge script script/DeployAuditorRegistry.s.sol --rpc-url $(ZKSYNC_SEPOLIA_RPC_URL) --private-key $(WALLET_PRIVATE_KEY) --legacy --zksync
