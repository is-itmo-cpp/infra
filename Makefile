.PHONY: all
all: functions

.PHONY: ansible-deps
ansible-deps:
	ansible-galaxy install -r ansible/requirements.yaml
	ansible-galaxy collection install -r ansible/requirements.yaml

.PHONY: deploy-runners
deploy-runners: ansible-deps
	ansible-playbook -i ansible/inventory.yaml -i ansible/secrets.yaml ansible/playbooks/runners.yaml

.PHONY: deploy-bot
deploy-bot: ansible-deps
	ansible-playbook -i ansible/inventory.yaml -i ansible/secrets.yaml ansible/playbooks/bot.yaml

.PHONY: deploy
deploy: deploy-bot deploy-runners

.PHONY: functions
functions: functions/vm-watch

.PHONY: functions/vm-watch
functions/vm-watch:
	mkdir -p dist
	-rm "dist/$(@F).zip"
	cd "$@"; 7z a "../../dist/$(@F).zip" * -xr!node_modules

.PHONY: clean
clean:
	-rm -rf dist
