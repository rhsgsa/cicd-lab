# Overview

A CICD pipeline has been provisioned in your OpenShift namespace. Let's take a look at the pipeline in the OpenShift Console.

01. Login to the [OpenShift Console]({{CONSOLE_URL}}) in a new browser tab - select the `ldap_provider` and enter your assigned username and password

01. Select the `{{USER_ID}}` project / Pipelines / `build-and-deploy`

01. The pipeline clones from a Java source git repo, builds the application, creates a container image, pushes the container image to an image registry, and deploys the image to your namespace in OpenShift

