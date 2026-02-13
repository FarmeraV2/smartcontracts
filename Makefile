include make/common.mk
include make/trust.mk
include make/process.mk
include make/audit.mk

BYTES32_IDENTIFIER = 0x2de837825143d8db1af63ebd5afd9feb6080222abcbda49b2018d11215a33241 # "value: log

deploy-anvil:
	cast rpc evm_mine --rpc-url $(RPC_URL) && \
	forge script script/Interaction.s.sol --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY) --broadcast

# deploy-sepolia:
# 	$(MAKE) -f make/process.mk process-deploy-sepolia \
# 	$(MAKE) -f make/trust.mk trust-deploy-sepolia

# deploy-zksync-anvil:
# 	$(MAKE) -f make/process.mk process-deploy-zksync-anvil \
# 	$(MAKE) -f make/trust.mk trust-deploy-zksync-anvil

# deploy-zksync-sepolia:
# 	$(MAKE) -f make/process.mk process-deploy-zksync-sepolia \
# 	$(MAKE) -f make/trust.mk trust-deploy-zksync-sepolia