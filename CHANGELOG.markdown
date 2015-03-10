## Master (unreleased)

* Enable autosquash mode when rebasing by default.

## 0.4.0 - 2014-02-20

* Prevent merging when the target branch is different from origin. Prevents
  commits in master from being accidentally pushed to origin along with the
  pull request.

## 0.3.1 - 2014-01-21

* Transfer ownership to Love With Food.
* Minor README updates.
* Add MIT license.

## 0.3.0 - 2013-12-14

* Rebase local PR branch from remote.
* Revamp test repo object helpers.

## 0.2.0 - 2013-12-03

* Fix: do not force-delete local PR branch.
* Fix: fetch origin and rebase master instead of git pull.
* Feature: be able to set merge message template.

## 0.1.3 - 2013-11-23

* Specify branches when pulling and pushing to origin.
* Abort script if pull request branch is master.

## 0.1.2 - 2013-11-14

* Force delete local pull request branch if it's been rebased.

## 0.1.1 - 2013-11-13

* Fix: app cannot find VERSION.

## 0.1.0 - 2013-11-12

* Initial release.
