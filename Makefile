HUB ?= harbor.zulong.com/keel-images
PROJECT ?= keel
REGIONS = cn os

$(foreach REGION,$(REGIONS),gen-$(REGION)): gen-%:
	helm -n $(PROJECT)-$* template --debug $(PROJECT)-$*-1 \
		--values ./charts/keel/values-$*.yaml \
		--set keel.region=$* --set keel.step=1 \
		./charts/keel > ./install/install-$*-1.yaml \

$(foreach REGION,$(REGIONS),deploy-$(REGION)): deploy-%:
	helm -n $(PROJECT)-$* upgrade --install $(PROJECT)-$*-1 \
		--values ./charts/keel/values-$*.yaml \
		--set keel.region=$* --set keel.step=1 \
		./charts/keel --create-namespace --timeout=20m

$(foreach REGION,$(REGIONS),undeploy-$(REGION)): undeploy-%:
	helm -n $(PROJECT)-$* uninstall $(PROJECT)-$*-1

$(foreach REGION,$(REGIONS),redeploy-$(REGION)): redeploy-%: undeploy-%s deploy-%s
