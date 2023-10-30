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


## Lab Instructions

The lab instructions are in the `workshop-content` directory. [Antora](https://docs.antora.org/antora/latest/) is used to convert the instructions from asciidoc to HTML.


### Adding content

If you wish to add content to the lab instructions,

01. Add a new asciidoc file to `workshop-content/documentation/modules/ROOT/pages/`; if you want to include images in your file, you can add the images to `workshop-content/documentation/modules/ROOT/assets/images/`

01. Add a `xref` to the new file to `workshop-content/modules/ROOT/pages/index.adoc` and `workshop-content/modules/ROOT/nav.adoc`


### Substitutions

*   If you want to substitute the username in your asciidoc files, insert [`%USER%` in the file](https://redhat-scholars.github.io/build-course/rhs-build-course/extras.html#using-credentials) and it will be substituted with the username - note that the `user` URL query parameter will need to be defined in the URL

*   If you want to avoid hardcoding text in your documents, you can make use of [asciidoc attributes](https://docs.asciidoctor.org/asciidoc/latest/attributes/reference-attributes/#reference-custom)

	*   You can define custom attributes in `site.yml` under `.asciidoc.attributes`

	*   You can then reference these attributes in your documents by surrounding them with curly braces - e.g. if you define an attribute named `my_server_url`, you can reference the attribute with `{my_server_url}`

	*   If you want to override the default value of the custom attribute defined in `site.yml` during build time, just set the value of the attribute using the [`--attribute` option when calling `antora generate`](https://docs.antora.org/antora/latest/cli/options/#generate-options)


### Previewing content locally

If you wish to preview the content on your local machine,

	cd workshop-content

	docker compose up

You can access the content at <http://localhost:3000>


### Changing the UI

If you wish to make changes to the UI,

01. Make the changes to the UI source files in `workshop-content/ui/src`

01. Spin up a container on your local machine

		cd workshop-content

		docker compose up

01. Generate a UI bundle

		docker exec -it antora /bin/sh

		cd ui

		yarn install

		gulp bundle

01. Modify `workshop-content/dev-site.yml` and change `.ui.bundle.url` to `./ui/build/ui-bundle.zip`

01. After you are done making your changes,

	*   Upload `workshop-content/ui/build/ui-bundle.zip` to the [github repo](https://github.com/rhsgsa/cicd-lab/) and publish it as a new release

	*   Modify `workshop-content/dev-site.yml` and `workshop-content/site.yml` - change `.ui.bundle.url` to the new release's download URL
