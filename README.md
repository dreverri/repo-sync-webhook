# Description

Sinatra app that handles HTTP POSTs from GitHub's post-receive
webhook.

# Usage

* Create the file `config/projects.yml`

* Add a project to the projects file

```yaml
path/to/deploy:
    name: repo-sync-webhook
    branch: master
    cmd: rake
```

* Use the `rackup` command to start the app on port `9292` bound to
  `0.0.0.0`

* Setup a [post receive
  hook](http://help.github.com/post-receive-hooks/) in the Github
  admin panel

# Config

Project definitions are specified in a `projects.yml` file.

# Projects

The config file should contain a hash of projects. The key of the hash
is used as the deploy path. Each project should define the following
parameters:

* name - Name of the repository
* branch - Name of the branch to respond to
* token - Token to be matched to incoming requests (optional)
* cmd - Command to run when the post commit hook is received

Each defined project should be specific to a particular repository and
branch. When the incoming request matches the defined repository,
branch, and token the cmd will be executed.

```yaml
path/to/deploy:
  name: repo-sync-webhook
  branch: master
  token: secret
  cmd: rake
```

# Deploy Path

The path defined for a project (e.g. `path/to/deploy`) stores the currently
processed commit. Each post receive hook creates a new directory
within the deploy path using the id of the received commit.

A symlink (`current`) is maintained which always points to the most
recently processed commit.

# Token

Projects may specify a token parameter. Incoming requests will be
expected to have a token query parameter with a value that matches the
value defined in the config file.

If a token is defined for a project the post commit URL should be
similar to `http://hostname:9292/notify?token=project_token`

# Process

When a post receive hook is received this app will do the following:

* Read repository name, branch name, and commit id from payload
* Look for matching projects in the config file
* Clone the repo to a new directory and checkout the commit
* Set the current working directory to this new directory
* Run the project's defined cmd
  * On success - update current symlink and remove old version
  * On failure - log the failure and destroy the commit directory

# To Do

* Use mutex per project rather than Sinatra's global mutex
* Package as a gem
