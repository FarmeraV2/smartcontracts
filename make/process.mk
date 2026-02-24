-include .env

PROCESS_DEPLOYED_ADDRESS = 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9

process-deploy-sepolia:
	forge script script/DeployProcessTracking.s.sol --rpc-url $(SEPOLIA_RPC_URL) --private-key $(WALLET_PRIVATE_KEY) --broadcast --etherscan-api-key $(SEPOLIA_API_KEY) --verify

process-deploy-anvil:
	forge script script/DeployProcessTracking.s.sol --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY) --broadcast

process-deploy-zksync-anvil:
	forge script script/DeployProcessTracking.s.sol --rpc-url $(ZKSYNC_RPC_URL) --private-key $(PRIVATE_KEY) --legacy --zksync

process-deploy-zksync-sepolia:
	forge script script/DeployProcessTracking.s.sol --rpc-url $(ZKSYNC_SEPOLIA_RPC_URL) --private-key $(WALLET_PRIVATE_KEY) --legacy --zksync

process-add-log:
	cast send $(PROCESS_DEPLOYED_ADDRESS) "addLog(uint64,uint64,string)" 1 1 "hash_abc" --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY)

process-get-log:
	cast call $(PROCESS_DEPLOYED_ADDRESS) "getLog(uint64)(string)" 1 --rpc-url $(RPC_URL)

process-get-logs:
	cast call $(PROCESS_DEPLOYED_ADDRESS) "getLogs(uint64)(uint64[],string[])" 1 --rpc-url $(RPC_URL)

process-add-step:
	cast send $(PROCESS_DEPLOYED_ADDRESS) "addStep(uint64,uint64,string)" 10 1 "step_hash" --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY)

process-get-step:
	cast call $(PROCESS_DEPLOYED_ADDRESS) "getStep(uint64)(string)" 1 --rpc-url $(RPC_URL)

process-get-steps:
	cast call $(PROCESS_DEPLOYED_ADDRESS) "getSteps(uint64)(uint64[],string[])" 10 --rpc-url $(RPC_URL)
