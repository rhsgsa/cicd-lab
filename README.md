# CICD Lab

This lab introduces participants to OpenShift Pipelines.

The pipeline clones a application source git repo, runs unit tests, builds the Go application, builds a container image, and deploys the manifests to the same namespace using `oc apply`.

ArgoCD is not used for CD.

## Installation using the remote installer

01. Provision an OpenShift Workshop cluster on `demo.redhat.com`

01. Login using `oc login`

01. Install with

		oc apply -f yaml/remote-installer.yaml

		oc logs -n remote-installer -f jobs/remote-installer

01. After the installation has completed, remove the remote installer

		oc delete -f yaml/remote-installer.yaml
