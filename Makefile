TERRAFORM ?= terraform
YC ?= yc

.PHONY: terraform-init
terraform-init:
	$(TERRAFORM) -chdir=terraform init

.PHONY: terraform-plan
terraform-plan: terraform-init
	@token="$$($(YC) iam create-token)" && YC_TOKEN="$$token" $(TERRAFORM) -chdir=terraform plan

.PHONY: terraform-apply
terraform-apply: terraform-init
	@token="$$($(YC) iam create-token)" && YC_TOKEN="$$token" $(TERRAFORM) -chdir=terraform apply

.PHONY: destroy
destroy: terraform-init
	@token="$$($(YC) iam create-token)" && YC_TOKEN="$$token" $(TERRAFORM) -chdir=terraform destroy
	$(MAKE) clean

.PHONY: ansible-deps
ansible-deps:
	ansible-galaxy collection install -r ansible/requirements.yaml

.PHONY: deploy-runners
deploy-runners: terraform-apply ansible-deps
	ansible-playbook -i generated/ansible-inventory.yaml -i secrets.yaml ansible/playbooks/runners.yaml

.PHONY: deploy
deploy: deploy-runners

.PHONY: clean
clean:
	-rm -rf generated
