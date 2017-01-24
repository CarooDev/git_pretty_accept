require 'English'
require 'spec_helper'
require 'rspec/example_steps'

describe GitPrettyAccept::App do
  let!(:project_path) { FileUtils.pwd }
  let(:tmp_path) { "tmp/git_pretty_accept" }

  let(:remote_path) { "#{tmp_path}/remote" }
  let(:our_path) { "#{tmp_path}/our" }
  let(:their_path) { "#{tmp_path}/their" }

  let(:pr_branch) { 'pr_branch' }

  let(:remote_repo) { RemoteRepo.new(project_path, remote_path) }
  let(:local_repo) do
    LocalRepo.new(project_path, our_path, remote_repo).tap do |result|
      result.add_initial_commit
    end
  end

  let(:other_repo) { LocalRepo.new(project_path, their_path, remote_repo) }

  before do
    FileUtils.rm_rf tmp_path
  end

  Steps "I can accept a pull request... prettily" do
    their_change_in_master = 'their_change_in_master'
    our_change_in_pr_branch = 'our_change_in_pr_branch'

    Given 'I have a local repo tracking a remote repo' do
      local_repo
    end

    And 'I have a PR_BRANCH that is not up-to-date with master' do
      other_repo.checkout 'master'
      other_repo.push_some_change their_change_in_master

      local_repo.checkout pr_branch
      local_repo.push_some_change our_change_in_pr_branch
    end

    And 'the current branch is master' do
      local_repo.checkout 'master'
    end

    When 'I run `git pretty-accept PR_BRANCH`' do
      local_repo.git_pretty_accept pr_branch
    end

    Then 'it should rebase the PR_BRANCH before merging to master' do
      expect(local_repo.git.log.size).to eq(4)

      expect(local_repo.git.log[0].message).to eq("Merge branch '#{pr_branch}'")
      expect(local_repo.git.log[0].parents.size).to eq(2)

      # For some reason, the order of the logs 1 and 2 is indeterminate.
      expect(local_repo.git.log[1 .. 2].map(&:message).sort)
        .to eq([our_change_in_pr_branch, their_change_in_master])

      expect(local_repo.git.log[1].parents.size).to eq(1)
      expect(local_repo.git.log[2].parents.size).to eq(1)

      expect(local_repo.git.log[3].parents.size).to eq(0)
    end

    And 'the PR_BRANCH should be on top of the previous origin/master' do
      commit_of_our_change_in_pr_branch = local_repo.git.log.find do |log|
        log.message == our_change_in_pr_branch
      end

      commit_of_their_change_in_master = local_repo.git.log.find do |log|
        log.message == their_change_in_master
      end

      expect(commit_of_our_change_in_pr_branch.parent.message)
        .to eq(commit_of_their_change_in_master.message)
    end

    And 'it should push the PR_BRANCH commits' do
      expect(local_repo.git.branches['origin/master'].gcommit.message)
        .to eq("Merge branch '#{pr_branch}'")
    end

    And 'it should delete the local PR_BRANCH' do
      expect(local_repo.git.branches[pr_branch]).to be_nil
    end

    And 'it should delete the remote PR_BRANCH' do
      expect(local_repo.git.branches["origin/#{pr_branch}"]).to be_nil
    end
  end

  Steps "should not allow master to be accepted as a PR branch" do
    Given 'I have a local repo' do
      local_repo
    end

    When 'I run `git pretty-accept master`' do
      command = "bundle exec #{project_path}/bin/git-pretty-accept --no-edit --no-autosquash master"
      FileUtils.cd(our_path) do
        @result = system(command, err: '/tmp/err.log')
      end
    end

    Then 'I should be informed that master cannot be accepted as a PR branch' do
      expect(@result).to be_false
      expect(File.read('/tmp/err.log')).to include(
        'trying to accept master as a pull request branch')
    end
  end

  Steps "should use the .git-pretty-accept-template.txt if available" do
    merge_message = "hello\nworld!"

    Given 'I have a local repo tracking a remote repo' do
      local_repo
    end

    And 'the local repo has a .git-pretty-accept-template.txt' do
      local_repo.add_merge_message_template_file merge_message
    end

    And 'I have a PR branch' do
      local_repo.create_branch pr_branch
      local_repo.commit_some_change 'some-change'
    end

    And 'the current branch is master' do
      local_repo.checkout 'master'
    end

    When 'I run `git pretty-accept PR_BRANCH`' do
      local_repo.git_pretty_accept pr_branch
    end

    Then 'I should see that the .git-pretty-accept-template.txt is the content of
      the merge message' do
      expect(local_repo.git.log[0].message).to eq(merge_message)
    end
  end

  Steps "should be able to use a .git-pretty-accept-template.txt with an apostrophe" do
    merge_message = "hello apostrophe (')"

    Given 'I have a local repo tracking a remote repo' do
      local_repo
    end

    And 'the local repo has a .git-pretty-accept-template.txt' do
      local_repo.add_merge_message_template_file merge_message
    end

    And 'I have a PR branch' do
      local_repo.create_branch pr_branch
      local_repo.commit_some_change 'some-change'
    end

    And 'the current branch is master' do
      local_repo.checkout 'master'
    end

    When 'I run `git pretty-accept PR_BRANCH`' do
      local_repo.git_pretty_accept pr_branch
    end

    Then 'I should see that the .git-pretty-accept-template.txt is the content of
      the merge message' do
      expect(local_repo.git.log[0].message).to eq(merge_message)
    end
  end

  Steps 'should rebase the branch from its remote branch' do
    local_pr_message = 'local-pr-branch-change.txt'
    remote_pr_message = 'remote-pr-branch-change.txt'

    Given 'I have a local repo tracking a remote repo' do
      local_repo
    end

    And 'I have a PR branch tracking a remote PR branch' do
      other_repo.create_branch pr_branch
      local_repo.track pr_branch
    end

    And 'both local and remote PR branch have been updated' do
      # Delay commit of local_pr_message by 1 full second. Git gem
      # seems to be confused when commits are too close to each other.
      sleep 1
      local_repo.commit_some_change local_pr_message

      other_repo.checkout pr_branch

      # Delay commit of remote_pr_message by 1 full second. Git gem
      # seems to be confused when commits are too close to each other.
      sleep 1
      other_repo.push_some_change remote_pr_message
    end

    And 'the current branch is master' do
      local_repo.checkout 'master'
    end

    When 'I run `git pretty-accept PR_BRANCH`' do
      local_repo.git_pretty_accept pr_branch
    end

    Then 'I should see the commit in the remote PR branch incorporated to master' do
      expect(local_repo.git.log.size).to eq(4)

      expect(local_repo.git.log[0].message).to eq("Merge branch '#{pr_branch}'")
      expect(local_repo.git.log[0].parents.size).to eq(2)

      expect(local_repo.git.log[1].message).to eq(local_pr_message)
      expect(local_repo.git.log[1].parents.size).to eq(1)

      expect(local_repo.git.log[2].message).to eq(remote_pr_message)
    end
  end

  Steps "should not merge into source branch when it is different from origin" do
    our_change_in_master = 'our_change_in_master'
    our_change_in_pr_branch = 'our_change_in_pr_branch'

    Given 'I have a local repo' do
      local_repo
    end

    And 'my local source branch is ahead of origin' do
      local_repo.checkout 'master'
      local_repo.commit_some_change our_change_in_master
    end

    And 'I have a PR_BRANCH that is not up-to-date with master' do
      local_repo.checkout pr_branch
      local_repo.push_some_change our_change_in_pr_branch
    end

    And 'the current branch is master' do
      local_repo.checkout 'master'
    end

    When 'I run `git pretty-accept PR_BRANCH`' do
      command =
        "bundle exec #{project_path}/bin/git-pretty-accept --no-edit --no-autosquash #{pr_branch}"

      FileUtils.cd(our_path) do
        @result = system(command, err: '/tmp/err.log')
      end
    end

    Then 'it should not merge the PR_BRANCH due to the commit in the local source branch' do
      expect(@result).to be_false
      expect(File.read('/tmp/err.log')).to include('git push origin master')
    end
  end
end
