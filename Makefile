TERRAFORM ?= terraform
YC ?= yc

TF_YC := $(TERRAFORM) -chdir=terraform/yc
TF_GITHUB := $(TERRAFORM) -chdir=terraform/github

.PHONY: yc-init yc-plan yc-apply yc-destroy
yc-init:
	$(TF_YC) init

yc-plan: yc-init
	@token="$$($(YC) iam create-token)" && YC_TOKEN="$$token" $(TF_YC) plan

yc-apply: yc-init
	@token="$$($(YC) iam create-token)" && YC_TOKEN="$$token" $(TF_YC) apply

yc-destroy: yc-init
	@token="$$($(YC) iam create-token)" && YC_TOKEN="$$token" $(TF_YC) destroy
	$(MAKE) clean

.PHONY: github-init github-plan github-apply
github-init:
	$(TF_GITHUB) init

github-plan: github-init
	$(TF_GITHUB) plan

github-apply: github-init
	$(TF_GITHUB) apply

.PHONY: ansible-deps
ansible-deps:
	ansible-galaxy collection install -r ansible/requirements.yaml

.PHONY: deploy-runners
deploy-runners: yc-apply github-apply ansible-deps
	ansible-playbook -i generated/ansible-inventory.yaml -i secrets.yaml ansible/playbooks/runners.yaml

.PHONY: deploy
deploy: deploy-runners

.PHONY: destroy
destroy: yc-destroy

.PHONY: clean
clean:
	-rm -rf generated
