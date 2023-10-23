# Tekton Pipeline

01. Fork this repo

01. In your forked repo

	*   Edit `registry-credentials.yaml` and change the value of `.stringData.username` to your username
	*   Edit `registry-credentials.yaml` and update the value of `.annotations.tekton.dev/docker-1` to match cluster ID
	*   Edit `eventlistener.yaml` and change the values of the `git-url-source` trigger bindings (`.spec.triggers`) to your username
	*   Edit `eventlistener.yaml` and change the values of the `output-image` trigger bindings (`.spec.triggers`) to your username and update cluster ID
	*   Edit `rox-secrets.yml` and update the values of `rox_central_endpoint` and `rox_api_token` as well as namespace to your username

01. Download the contents of the forked repo and apply all the `.yaml` manifests that starts with `rox-` first before applying the rest of the `.yaml` manifests to your namespace

