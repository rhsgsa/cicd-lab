WORKSHOPPER_STAGING=/tmp/content

BASE:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

include $(BASE)/config.sh

.PHONY: install deploy-ldap install-gitea install-openshift-pipelines install-openshift-storage install-redhat-quay install-rhacs-central provision-student-accounts deploy-get-a-username deploy-workshopper local-workshopper prep-workshopper-paths

install: deploy-ldap install-gitea install-openshift-pipelines install-openshift-storage install-redhat-quay install-rhacs-central provision-student-accounts deploy-workshopper deploy-get-a-username

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
	sed "s|value: 'registry-quay[^/]*|value: '$$REGISTRY_HOSTNAME|" \
	  $(BASE)/pipeline/eventlistener.yaml \
	  > /tmp/pipeline/eventlistener.yaml

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


deploy-workshopper: prep-workshopper-paths
	oc new-build \
	  --name workshopper \
	  -n $(WORKSHOPPER_PROJ) \
	  --binary \
	  --strategy source \
	  --image quay.io/kwkoo/workshopper-uid:1.0
	@/bin/echo -n "waiting for buildconfig to appear..."
	@until oc get -n $(WORKSHOPPER_PROJ) bc/workshopper >/dev/null 2>/dev/null; do \
	  /bin/echo -n "."; \
	  sleep 5; \
	done
	@echo "done"
	oc start-build -n $(WORKSHOPPER_PROJ) workshopper --from-dir=$(WORKSHOPPER_STAGING) --follow
	sed 's|\(image: [^/]*\)/[^/]*/\(.*\)|\1/$(WORKSHOPPER_PROJ)/\2|' $(BASE)/yaml/workshopper.yaml | oc apply -n $(WORKSHOPPER_PROJ) -f -
	oc set env -n $(WORKSHOPPER_PROJ) deploy/workshopper \
	  CONSOLE_URL=`oc whoami --show-console` \
	  GIT_URL="https://gitea-$(GIT_PROJ).`oc whoami --show-console | sed 's/[^.]*\.//'`"
	rm -rf $(WORKSHOPPER_STAGING)


local-workshopper: prep-workshopper-paths
	docker run \
	  --name workshopper \
	  -it \
	  --rm \
	  -p 8080:8080 \
	  -v $(WORKSHOPPER_STAGING):/workshopper/content \
	  -e CONTENT_URL_PREFIX="file:///workshopper/content" \
	  -e LOG_TO_STDOUT=true \
	  -e WORKSHOPS_URLS="file:///workshopper/content/_workshop.yml" \
	  -e CONSOLE_URL="https://console-openshift-console.apps.environment.com" \
	  quay.io/openshiftlabs/workshopper:1.0
	rm -rf $(WORKSHOPPER_STAGING)


prep-workshopper-paths:
	rm -rf $(WORKSHOPPER_STAGING)
	mkdir -p $(WORKSHOPPER_STAGING)
	tar -C $(BASE)/workshopper -cf - . | tar -C $(WORKSHOPPER_STAGING) -xf -
	cd $(BASE)/workshopper \
	&& \
	for f in *.md; do \
	  sed 's|!\[\(.*\)\](images/\(.*\))|![\1](/workshop/cicd-workshop/asset/images/\2)|g' $$f > $(WORKSHOPPER_STAGING)/$$f; \
	done

