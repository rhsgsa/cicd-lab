WORKSHOPPER_STAGING=/tmp/content
ROX_API_TOKEN=/tmp/roxtoken

BASE:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

include $(BASE)/config.sh

.PHONY: install deploy-ldap install-openshift-pipelines install-openshift-storage install-redhat-quay install-rhacs-central install-gitea provision-student-accounts deploy-get-a-username deploy-antora

install: deploy-ldap install-openshift-pipelines install-openshift-storage install-redhat-quay install-rhacs-central install-gitea provision-student-accounts deploy-antora deploy-get-a-username
	@echo "done"


install-gitea:
	$(BASE)/scripts/deploy-gitea

	# prepare sample-app git repo for instructor
	-rm -rf /tmp/sample-app
	cd $(BASE) \
	&& \
	tar -cf - sample-app | tar -C /tmp -xf -

	REGISTRY_HOSTNAME=registry-quay-quay-enterprise.`oc whoami --show-console | sed 's/^[^.]*\.//'` \
	&& \
	sed 's|image: .*|image: '"$$REGISTRY_HOSTNAME/userX/simpleweb-training:latest|" $(BASE)/sample-app/yaml/deployment.yaml > /tmp/sample-app/yaml/deployment.yaml

	# prepare pipeline git repo for instructor
	-rm -rf /tmp/pipeline
	cd $(BASE) \
	&& \
	tar -cf - pipeline | tar -C /tmp -xf -

	REGISTRY_HOSTNAME=registry-quay-quay-enterprise.`oc whoami --show-console | sed 's/^[^.]*\.//'` \
	STUDENT_PASSWORD=$(STUDENT_PASSWORD) \
	envsubst \
	  < $(BASE)/pipeline/registry-credentials.yaml \
	  > /tmp/pipeline/registry-credentials.yaml

	REGISTRY_HOSTNAME=registry-quay-quay-enterprise.`oc whoami --show-console | sed 's/^[^.]*\.//'` \
	&& \
	sed \
	  "s|value: 'registry-quay[^/]*|value: '$$REGISTRY_HOSTNAME|" \
	  $(BASE)/pipeline/eventlistener.yaml \
	  > /tmp/pipeline/eventlistener.yaml

	# ensure that ACS is deployed before we generate an ACS API token
	@/bin/echo -n "waiting for ACS route to appear..."; \
	while true; do \
	  ROX_HOST="`oc get -n stackrox route/central -o jsonpath='{.spec.host}'`"; \
	  if [ -n "$$ROX_HOST" ]; then break; fi; \
	  /bin/echo -n "."; \
	  sleep 5; \
	done; \
	echo "ACS endpoint is at $$ROX_HOST"; \
	/bin/echo -n "waiting for ACS API to come up..."; \
	while [ "`curl -sk "https://$$ROX_HOST/v1/ping" 2>/dev/null | jq -r .status`" != "ok" ]; do \
	  /bin/echo -n "."; \
	  sleep 5; \
	done; \
	echo "done"; \
	/bin/echo -n "waiting for ACS credentials secret to appear..."; \
	until oc get -n stackrox secret/central-htpasswd >/dev/null 2>/dev/null; do \
	  /bin/echo -n "."; \
	  sleep 5; \
	done; \
	echo "done"; \
	ROX_PASSWORD="`oc extract -n stackrox secret/central-htpasswd --to=- --keys=password 2>/dev/null`"; \
	if [ -z "$$ROX_PASSWORD" ]; then \
	  echo "could not get ACS admin password"; \
	  exit 1; \
	fi; \
	ROX_TOKEN=`curl -sk -u "admin:$$ROX_PASSWORD" "https://$$ROX_HOST/v1/apitokens/generate" -d '{"name":"pipeline","role":"Admin"}' | jq -r .token`; \
	if [ -z "$$ROX_TOKEN" ]; then \
	  echo "could not generate ACS API token"; \
	  exit 1; \
	fi; \
	echo "ACS API token is $$ROX_TOKEN"; \
	/bin/echo -n $$ROX_TOKEN > $(ROX_API_TOKEN)

	sed \
	  -e "s|rox_central_endpoint: .*|rox_central_endpoint: `oc get -n stackrox route/central -o jsonpath='{.spec.host}'`:443|" \
	  -e "s|rox_api_token: .*|rox_api_token: `cat $(ROX_API_TOKEN)`|" \
	  $(BASE)/pipeline/rox-secrets.yml \
	  > /tmp/pipeline/rox-secrets.yml
	rm -f $(ROX_API_TOKEN)

	@$(BASE)/scripts/init-gitea \
	  $(GIT_PROJ) gitea $(GIT_ADMIN) $(GIT_PASSWORD) $(GIT_ADMIN)@example.com \
	  /tmp/sample-app sample-app "Simple web service" \
	  /tmp/pipeline pipeline "Tekton pipeline"

	rm -rf /tmp/sample-app
	rm -rf /tmp/pipeline

	# configure gitea to authenticate users against LDAP
	oc rsh -n $(GIT_PROJ) sts/gitea \
	  gitea admin auth add-ldap-simple \
	    --name ldap \
		--active \
		--security-protocol unencrypted \
		--skip-tls-verify \
		--host ldap.$(LDAP_PROJ).svc.cluster.local \
		--port 1389 \
		--user-dn 'cn=%s,ou=users,$(LDAP_ROOT)' \
		--user-filter '(cn=%s)' \
		--email-attribute mail


install-openshift-pipelines:
	@echo "installing OpenShift Pipelines..."
	@$(BASE)/scripts/install-openshift-pipelines


install-openshift-storage:
	@echo "installing OpenShift Storage for Noobaa..."
	@$(BASE)/scripts/install-openshift-storage


install-redhat-quay:
	@echo "installing Red Hat Quay..."
	@$(BASE)/scripts/install-quay
	$(BASE)/scripts/configure-quay-ldap-auth


install-rhacs-central:
	@echo "installing Red Hat Advanced Cluster Security Central..."
	@$(BASE)/scripts/install-rhacs-central


deploy-ldap:
	$(BASE)/scripts/deploy-ldap
	oc wait -n $(LDAP_PROJ) deploy/ldap --for condition=Available=True --timeout=120s
	@if [ `oc get oauth cluster -o name 2>/dev/null | wc -l` -lt 1 ]; then \
	  echo "could not find oauth/cluster resource"; \
	  exit 1; \
	fi
	oc patch oauth/cluster --type json -p '[{"op":"add","path":"/spec/identityProviders/-","value":{"name":"ldap_provider","mappingMethod":"claim","type":"LDAP","ldap":{"attributes":{"id":["uid"],"email":["mail"],"name":["cn"],"preferredUsername":["uid"]},"insecure":true,"url":"ldap://ldap.$(LDAP_PROJ).svc.cluster.local:1389/ou=users,$(LDAP_ROOT)?cn"}}}]'
	oc delete -n openshift-authentication po -l app=oauth-openshift


provision-student-accounts:
	$(BASE)/scripts/create-user-projects

	# this script also applies the pipeline manifests in the user namespaces
	$(BASE)/scripts/upload-user-git-repos


deploy-get-a-username:
	$(BASE)/scripts/deploy-get-a-username


deploy-antora:
	oc new-build \
	  -n $(ANTORA_PROJ) \
	  --name antora \
	  --binary \
	  --build-arg=CONSOLE_URL="`oc whoami --show-console`" \
	  --build-arg=GIT_URL="https://gitea-$(GIT_PROJ).`oc whoami --show-console | sed 's/^[^.]*\.//'`" \
	  --strategy docker
	@/bin/echo -n "waiting for build config to appear..."
	@until oc get -n $(ANTORA_PROJ) bc/antora >/dev/null 2>/dev/null; do \
	  echo -n "."; \
	  sleep 5; \
	done
	@echo "done"
	oc start-build antora \
	  -n $(ANTORA_PROJ) \
	  --from-dir=$(BASE)/workshop-content \
	  --follow
	oc create deploy workshop-content \
	  -n $(ANTORA_PROJ) \
	  --image=image-registry.openshift-image-registry.svc:5000/$(ANTORA_PROJ)/antora \
	  --port 8080
	oc expose -n $(ANTORA_PROJ) deploy/workshop-content
	oc expose -n $(ANTORA_PROJ) svc/workshop-content
	oc patch route/workshop-content \
	  -n $(ANTORA_PROJ) \
	  -p '{"spec":{"tls":{"termination":"edge","insecureEdgeTerminationPolicy":"Allow"}}}'
