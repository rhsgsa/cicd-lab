# Tekton Pipeline

01. Fork this repo

01. In your forked repo

	*   Edit `registry-credentials.yaml` and change the value of `.stringData.username` to your username
	*   Edit `eventlistener.yaml` and change the values of the `git-url-source` and `output-image` trigger bindings (`.spec.triggers`) to your username

01. Download the contents of the forked repo and apply all the `.yaml` manifests to your namespace

