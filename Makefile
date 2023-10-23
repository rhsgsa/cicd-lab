BASE:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

include $(BASE)/config.sh

.PHONY: install

install: deploy-ldap install-gitea install-openshift-pipelines provision-student-accounts deploy-get-a-username
	@echo "done"


install-gitea:
	$(BASE)/scripts/deploy-gitea

	-rm -rf /tmp/sample-app
	cd $(BASE) \
	&& \
	tar -cf - sample-app | tar -C /tmp -xf -

	GIT_HOST=`oc get -n $(GIT_PROJ) route/gitea -o jsonpath='{.spec.host}'` \
	&& \
	sed 's|image: .*|image: '"$$GIT_HOST/userX/simpleweb-training:latest|" $(BASE)/sample-app/yaml/deployment.yaml > /tmp/sample-app/yaml/deployment.yaml

	-rm -rf /tmp/pipeline
	cd $(BASE) \
	&& \
	tar -cf - pipeline | tar -C /tmp -xf -

	REGISTRY_HOSTNAME=`oc get -n $(GIT_PROJ) route/gitea -o jsonpath='{.spec.host}'` GIT_PROJ=$(GIT_PROJ) STUDENT_PASSWORD=$(STUDENT_PASSWORD) envsubst < $(BASE)/pipeline/registry-credentials.yaml > /tmp/pipeline/registry-credentials.yaml

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
