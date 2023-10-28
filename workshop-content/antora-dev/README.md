Use the image in this directory to develop content - a rebuild will be triggered and the browser reloaded whenever a change is made to the content.

To use this image,

01. Build the image

		docker build -t antora-dev .

01. Run the image

		./run-local

		yarn install

		# antora expects /antora to contain a git repo
		git init
		git config --global --add safe.directory /antora
		git config --global user.email "user@example.com"
		git config --global user.name "user"
		git commit --allow-empty -m init

		gulp

01. After you're done, don't forget to remove the `.git` directory
