-include .env

process-deploy-sepolia:
	forge script script/DeployProcessTracking.s.sol --rpc-url $(SEPOLIA_RPC_URL) --private-key $(WALLET_PRIVATE_KEY) --broadcast --etherscan-api-key $(SEPOLIA_API_KEY) --verify

process-deploy-anvil:
	forge script script/DeployProcessTracking.s.sol --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY) --broadcast

process-deploy-zksync-anvil:
	forge script script/DeployProcessTracking.s.sol --rpc-url $(ZKSYNC_RPC_URL) --private-key $(PRIVATE_KEY) --legacy --zksync

process-deploy-zksync-sepolia:
	forge script script/DeployProcessTracking.s.sol --rpc-url $(ZKSYNC_SEPOLIA_RPC_URL) --private-key $(WALLET_PRIVATE_KEY) --legacy --zksync

process-add-log:
	cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "addLog(uint64,uint64,uint64,string)" 1 1 1 "hash_abc" --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY)

process-get-log:
	cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "getLog(uint64)" 1 --rpc-url $(RPC_URL)

process-get-logs:
	cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "getLogs(uint64,uint64)" 1 1 --rpc-url $(RPC_URL)

process-decode-logs:
	cast decode-abi "getLogs(uint64,uint64)(uint64[],string[])" 0x0000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000008686173685f616263000000000000000000000000000000000000000000000000

process-add-step:
	cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "addStep(uint64,uint64,string)" 10 1 "step_hash" --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY)

process-get-step:
	cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "getStep(uint64,uint64)" 10 1 --rpc-url $(RPC_URL)

process-get-steps:
	cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "getSteps(uint64)" 10 --rpc-url $(RPC_URL)
