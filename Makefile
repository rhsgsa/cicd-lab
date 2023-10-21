BASE:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

include $(BASE)/config.sh

.PHONY: install

install: install-gitea install-openshift-pipelines provision-student-accounts deploy-get-a-username
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


install-openshift-pipelines:
	@echo "installing OpenShift Pipelines..."
	@$(BASE)/scripts/install-openshift-pipelines


deploy-ldap:
	$(BASE)/scripts/deploy-ldap
	oc apply -f $(BASE)/yaml/ldap-oauth.yaml


provision-student-accounts:
	$(BASE)/scripts/create-htpasswd-logins
	$(BASE)/scripts/create-user-projects
	$(BASE)/scripts/create-gitea-user-accounts


deploy-get-a-username:
	$(BASE)/scripts/deploy-get-a-username
