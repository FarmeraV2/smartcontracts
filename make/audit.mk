AUDIT_DEPLOYED_ADDRESS = 0x3B02fF1e626Ed7a8fd6eC5299e2C54e1421B626B # always change
VRF_COORDINATOR = 0xe7f1725e7734ce288f8367e1bb143e90bb3f0512 # always change with deploy
VRF_REQUEST_ID = 1
WALLET_ADDRESS = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720
# default: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
# Alex: 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720
# Bob: 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f
# Chloe: 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955
# Doe: 0x976EA74026E726554dB657fA54763abd0C3a0aa9
# Jane: 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc
# John: 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65

AUDIT_VERIFICATION_REQUESTED_HASH := $(shell cast keccak "VerificationRequested(bytes32,uint256,address[],uint256)")

audit-deploy-sepolia:
	forge script script/DeployAuditorRegistry.s.sol --tc DeployAuditorRegistry --rpc-url $(SEPOLIA_RPC_URL) --private-key $(WALLET_PRIVATE_KEY) --broadcast --etherscan-api-key $(SEPOLIA_API_KEY) --verify

audit-deploy-anvil:
	cast rpc evm_mine && \
	forge script script/DeployAuditorRegistry.s.sol --tc DeployAuditorRegistry --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY) --broadcast

audit-deploy-zksync-anvil:
	forge script script/DeployAuditorRegistry.s.sol --rpc-url $(ZKSYNC_RPC_URL) --private-key $(PRIVATE_KEY) --legacy --zksync

audit-deploy-zksync-sepolia:
	forge script script/DeployAuditorRegistry.s.sol --rpc-url $(ZKSYNC_SEPOLIA_RPC_URL) --private-key $(WALLET_PRIVATE_KEY) --legacy --zksync

audit-register-auditor:
	cast send $(AUDIT_DEPLOYED_ADDRESS) "registerAuditor(string)" "John" --value 1ether --private-key $(PRIVATE_KEY) --rpc-url $(RPC_URL)

audit-get-auditor:
	cast call $(AUDIT_DEPLOYED_ADDRESS) "getAuditor(address)((bool,address,uint256,uint256,string))" $(WALLET_ADDRESS) --rpc-url $(RPC_URL)

audit-register-auditors:
	cast send $(AUDIT_DEPLOYED_ADDRESS) "registerAuditor(string)" "Alex" --value 1ether --private-key 0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6 --rpc-url $(RPC_URL) && \
	cast send $(AUDIT_DEPLOYED_ADDRESS) "registerAuditor(string)" "Bob" --value 1ether --private-key 0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97 --rpc-url $(RPC_URL) && \
	cast send $(AUDIT_DEPLOYED_ADDRESS) "registerAuditor(string)" "Chloe" --value 1ether --private-key 0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356 --rpc-url $(RPC_URL) && \
	cast send $(AUDIT_DEPLOYED_ADDRESS) "registerAuditor(string)" "Doe" --value 1ether --private-key 0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e --rpc-url $(RPC_URL) && \
	cast send $(AUDIT_DEPLOYED_ADDRESS) "registerAuditor(string)" "Jane" --value 1ether --private-key 0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba --rpc-url $(RPC_URL)
# 	cast send $(AUDIT_DEPLOYED_ADDRESS) "registerAuditor(string)" "John" --value 1ether --private-key 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a --rpc-url $(RPC_URL)

audit-request:
	cast send $(AUDIT_DEPLOYED_ADDRESS) "requestVerification(bytes32,uint64,uint256)" $(BYTES32_IDENTIFIER) 1 1770985796 --private-key $(PRIVATE_KEY) --rpc-url $(RPC_URL)

audit-fulfill-vrf: # need to fulfull manually
	cast rpc evm_mine && cast rpc evm_mine && cast rpc evm_mine && \
	cast send $(VRF_COORDINATOR) "fulfillRandomWords(uint256,address)" $(VRF_REQUEST_ID) $(AUDIT_DEPLOYED_ADDRESS) --private-key $(PRIVATE_KEY) --rpc-url $(RPC_URL)

vrd-current-id:
	cast call $(VRF_COORDINATOR) "s_currentRequestId()" --rpc-url $(RPC_URL)

audit-get-assignments:
	cast call $(AUDIT_DEPLOYED_ADDRESS) "getVerificationAssignments(bytes32,uint64)(address[])" $(BYTES32_IDENTIFIER) 1 --rpc-url $(RPC_URL)

audit-get-deadline:
	cast call $(AUDIT_DEPLOYED_ADDRESS) "getVerificationDeadline(bytes32,uint64)(uint256)" $(BYTES32_IDENTIFIER) 1 --rpc-url $(RPC_URL)

audit-verify:
	cast send $(AUDIT_DEPLOYED_ADDRESS) "verify(bytes32,uint64,bool)" $(BYTES32_IDENTIFIER) 63 false --private-key 0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6 --rpc-url $(RPC_URL) && \
	cast send $(AUDIT_DEPLOYED_ADDRESS) "verify(bytes32,uint64,bool)" $(BYTES32_IDENTIFIER) 63 false --private-key 0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97 --rpc-url $(RPC_URL) && \
	cast send $(AUDIT_DEPLOYED_ADDRESS) "verify(bytes32,uint64,bool)" $(BYTES32_IDENTIFIER) 63 false --private-key 0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356 --rpc-url $(RPC_URL) && \
	cast send $(AUDIT_DEPLOYED_ADDRESS) "verify(bytes32,uint64,bool)" $(BYTES32_IDENTIFIER) 63 true --private-key 0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e --rpc-url $(RPC_URL) && \
	cast send $(AUDIT_DEPLOYED_ADDRESS) "verify(bytes32,uint64,bool)" $(BYTES32_IDENTIFIER) 63 true --private-key 0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba --rpc-url $(RPC_URL) 
# 	cast send $(AUDIT_DEPLOYED_ADDRESS) "verify(bytes32,uint64,bool)" $(BYTES32_IDENTIFIER) 63 false --private-key 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a --rpc-url $(RPC_URL)

audit-finalize-expired:
	cast send $(AUDIT_DEPLOYED_ADDRESS) "finalizeExpired(bytes32,uint64)" $(BYTES32_IDENTIFIER) 1 --private-key $(PRIVATE_KEY) --rpc-url $(RPC_URL)

audit-get-verifications:
	cast call $(AUDIT_DEPLOYED_ADDRESS) "getVerifications(bytes32,uint64)((bool,address,uint256)[])" $(BYTES32_IDENTIFIER) 93 --rpc-url $(RPC_URL)

audit-get-finalized:
	cast call $(AUDIT_DEPLOYED_ADDRESS) "finalized(bytes32,uint64)(bool)" $(BYTES32_IDENTIFIER) 1 --rpc-url $(RPC_URL)

audit-get-finalized-result:
	cast call $(AUDIT_DEPLOYED_ADDRESS) "getVerificationResult(bytes32,uint64)(bool)" $(BYTES32_IDENTIFIER) 1 --rpc-url $(RPC_URL)

audit-verification-finalized-events:
	cast logs \
	--from-block 0 \
	--to-block latest \
	"VerificationFinalized(bytes32,uint64,bool,uint256,uint256)" \
	--rpc-url $(RPC_URL)

audit-request-events:
	cast logs \
	--from-block 0 \
	--to-block latest \
	"VerificationRequested(bytes32,uint64,address[],uint256)" \
	--rpc-url $(RPC_URL)

audit-start-anvil: audit-deploy-anvil audit-register-auditors