HUB ?= harbor.zulong.com/keel-images
NAMESPACE ?= keel-test
RELEASE ?= keel-test

.PHONY: gen
gen:
	helm -n $(NAMESPACE) template --debug $(RELEASE) ./charts/keel > ./install.yaml

.PHONY: deploy
deploy:
	helm -n $(NAMESPACE) upgrade --install $(RELEASE) ./charts/keel --create-namespace --timeout=20m

.PHONY: undeploy
undeploy:
	helm -n $(NAMESPACE) delete $(RELEASE)

.PHONY: redeploy
redeploy: undeploy deploy
