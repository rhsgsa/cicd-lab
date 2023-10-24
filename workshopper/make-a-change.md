In this module, we will make a change to the application. This should trigger the pipeline, initiating build and deployment of the application.

01. Open [`main.go` in the `sample-app` git repo]({{GIT_URL}}/{{USER_ID}}/sample-app/src/branch/main/main.go){:target="git"}

01. Click on Edit File

	![Edit File](/workshop/cicd-workshop/asset/images/edit_file.png)

01. Change the greeting in line 26 from `Hello` to `Good afternoon`

01. Commit the change

	![Commit Change](/workshop/cicd-workshop/asset/images/commit_change.png)

01. Switch back to the OpenShift Console - a new pipeline run should have been triggered by the webhook

01. Wait for the pipeline run to complete

01. Go back to the Topology view - you should see a new pod spinning up

01. When the new pod comes up successfully, click on `simpleweb`'s route again - the new greeting should appear
