# Initial Build

In this module, we will trigger the pipeline for the first time. We will do this by triggering a webhook from the application source git repo.

01. Open the [application source git repo]({{GIT_URL}}/{{USER_ID}}/sample-app) in a new browser tab

01. Sign in using your assigned username and password

01. A webhook has been configured in this git repo to trigger the pipeline - examine the webhook by selecting Settings / Webhooks / `http://el-build-and-deploy...`

01. Trigger the webhook by scrolling to the bottom of the page and clicking on Test Delivery

01. Examine the [PipelineRuns screen in the OpenShift Console]({{CONSOLE_URL}}/pipelines/ns/{{USER_ID}}/pipeline-runs) - you should see a new pipeline run running

01. Wait for the pipeline run to complete

01. Select the Developer perspective / Topology - you should see the `simpleweb` Deployment spinning up

01. Click on the `simpleweb` route - you should see a greeting from the web service
