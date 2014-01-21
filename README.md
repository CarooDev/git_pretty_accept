# git-pretty-accept

`git-pretty-accept` is a script that rebases a pull request before merging
to master. Pull requests are _always_ merged recursively. The result is a
linear history with merge bubbles indicating pull requests. In short, pretty.

For more information, check out

* [A simple git branching model](https://gist.github.com/jbenet/ee6c9ac48068889b0912)
* [Best Way To Merge A (GitHub) Pull Request](http://differential.io/blog/best-way-to-merge-a-github-pull-request)

`git-pretty-accept` also automatically deletes the local and remote branch
of the pull request once it's merged to master. I may add an option later on
to disable this by default.

## Installation

Add this line to your application's Gemfile:

    gem 'git_pretty_accept'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install git_pretty_accept

## Usage

To accept a pull request, just run `git pretty-accept BRANCH_NAME` in
the branch where `BRANCH_NAME` will be merged.

## Merge commit template

You can also provide a merge commit template
`.git-pretty-accept-template.txt` to your project directory. This is
great if you want your merge commits to follow a certain format e.g.
you want your team to enter the issue link when accepting pull requests.

## Caveats

We wrote git_pretty_accept for our particular workflow. If you'd like
to use the gem, here are a few things you'll need to keep in mind. The
script

1. Assumes that your remote repository is origin. It doesn't work yet with
   Github forks.
1. Automatically removes the local and remote branch of the pull request
   once the pull request is merged.
1. Complains if you accidentally try to accept the master branch to a feature
   branch.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
