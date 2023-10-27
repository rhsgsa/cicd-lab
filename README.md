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


## Manual configuration steps

Some manual configuration is required for Quay and ACS. Perform the following to setup the account for every participant (e.g. `user1`, `user2`, etc)

01. Access quay with a web browser, logging in as the user - `userX` / `redhat`

01. Create a new repository named `simpleweb-training`

01. Create a robot account in the new repository and give it read permissions to the repository

01. Copy the robot account's username and token - use this to create a quay integration in ACS for the user

These manual steps are needed because quay will only create a user account for the user on initial login. If you do not login, you will get an error while trying to push an image to quay even if you present the correct credentials.

You need to create a robot account in order for the ACS CLI to be able to access the image in quay.
