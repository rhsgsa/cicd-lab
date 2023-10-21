# Sample Go Service

01. Fork this repo

01. In your forked repo

	*   Select Settings / Webhooks / Add Webhook / Gitea

	*   Set the form fields to the following

		|Field|Value|
		|---|---|
		|Target URL|`http://el-build-and-deploy.userX.svc:8080` (replace `userX` with your actual username)|
		|HTTP Method|POST|
		|POST Content Type|application/json|

	*   Click Add Webhook
