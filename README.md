# CICD Lab

This lab introduces participants to OpenShift Pipelines.

The pipeline clones a application source git repo, runs unit tests, builds the Go application, builds a container image, and deploys the manifests to the same namespace using `oc apply`.

ArgoCD is not used for CD.

## Installation

01. Provision an OpenShift Workshop cluster on `demo.redhat.com`

01. Login using `oc login`

01. Install with

		make install


## Particpant Instructions

01. Obtain a username and password from `get-a-username` (deployed in the `infra` namespace) - the username and password is used for OpenShift and gitea

01. Login to `gitea` and fork the `instructor/sample-app` and `instructor-pipeline` repos

01. Make changes to the forked `sample-app` repo and setup a webhook according to the instructions in `README.md`

01. Make changes to the forked `pipeline` repo according to the instructions in `README.md`, then apply manifests to the participant namespace in OpenShift

01. After the pipeline has been deployed, test the webhook in the forked `sample-app` repo - this should trigger a `PipelineRun`

01. After the pipeline has completed successfully, the `simpleweb` application should be depoyed

01. Test the application by accessing the route

01. Edit `main.go` in the `sample-app` repo, change the greeting message from `Hello` to `Hello there` (line 26) and commit the change

01. The webhook should fire, and a new `PipelineRun` should be created

01. After the pipeline has completed successfully, the `simpleweb` application should be updated to the new version

01. Access the `simpleweb` route - the new greeting should be displayed
