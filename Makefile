include make/common.mk
include make/trust.mk
include make/process.mk
include make/audit.mk

BYTES32_IDENTIFIER = 0x2de837825143d8db1af63ebd5afd9feb6080222abcbda49b2018d11215a33241

deploy-anvil: 
	$(MAKE) -f make/process.mk process-deploy-anvil \
	$(MAKE) -f make/trust.mk trust-deploy-anvil \
	$(MAKE) -f make/audit.mk audit-deploy-anvil

deploy-sepolia:
	$(MAKE) -f make/process.mk process-deploy-sepolia \
	$(MAKE) -f make/trust.mk trust-deploy-sepolia

deploy-zksync-anvil:
	$(MAKE) -f make/process.mk process-deploy-zksync-anvil \
	$(MAKE) -f make/trust.mk trust-deploy-zksync-anvil

deploy-zksync-sepolia:
	$(MAKE) -f make/process.mk process-deploy-zksync-sepolia \
	$(MAKE) -f make/trust.mk trust-deploy-zksync-sepolia