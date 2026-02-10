include make/common.mk
include make/trust.mk
include make/process.mk
include make/audit.mk

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