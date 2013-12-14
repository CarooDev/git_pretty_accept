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

  before do
    FileUtils.rm_rf tmp_path
  end

  Steps "I can accept a pull request... prettily" do
    our = nil

    Given 'I have a local repo tracking a remote repo' do
      Git.init remote_path, bare: true

      # Add initial commit. Otherwise, `our.branch(pr_branch)`
      # below won't be able to create a new branch.

      Git.clone remote_path, our_path
      our = Git.open(our_path)

      File.open("#{our_path}/readme.txt", 'w') { |f| f.write('readme') }
      our.add all: true
      our.commit 'Add readme'
      our.push
    end

    And 'I have a PR_BRANCH that is not up-to-date with master' do
      Git.clone remote_path, their_path
      their = Git.open(their_path)

      File.open("#{their_path}/readme.txt", 'w') { |f| f.write('updated readme') }
      their.add all: true
      their.commit 'Update readme'
      their.push

      our.branch(pr_branch).checkout
      File.open("#{our_path}/changelog.txt", 'w') { |f| f.write('changelog') }
      our.add all: true
      our.commit 'Add changelog'
      our.push our.remote('origin'), pr_branch
    end

    And 'the current branch is master' do
      our.branch('master').checkout
    end

    When 'I run `git pretty-accept PR_BRANCH`' do
      FileUtils.cd(our_path) do
        `bundle exec #{project_path}/bin/git-pretty-accept --no-edit #{pr_branch}`
        expect($CHILD_STATUS.exitstatus).to eq(0)
      end
    end

    Then 'it should rebase the PR_BRANCH before merging to master' do
      expect(our.log.size).to eq(4)

      expect(our.log[0].message).to eq("Merge branch 'pr_branch'")
      expect(our.log[0].parents.size).to eq(2)

      # For some reason, the order of the logs 1 and 2 is indeterminate.
      expect(our.log[1 .. 2].map(&:message).sort)
        .to eq(['Add changelog', 'Update readme'])

      expect(our.log[1].parents.size).to eq(1)
      expect(our.log[2].parents.size).to eq(1)

      expect(our.log[3].message).to eq('Add readme')
      expect(our.log[3].parents.size).to eq(0)
    end

    And 'it should push the PR_BRANCH commits' do
      expect(our.branches['origin/master'].gcommit.message)
        .to eq("Merge branch 'pr_branch'")
    end

    And 'it should delete the local PR_BRANCH' do
      expect(our.branches[pr_branch]).to be_nil
    end

    And 'it should delete the remote PR_BRANCH' do
      expect(our.branches["origin/#{pr_branch}"]).to be_nil
    end
  end

  Steps "should not allow master to be accepted as a PR branch" do
    Given 'I have a local repo' do
      Git.init(our_path)
    end

    When 'I run `git pretty-accept master`' do
      command = "bundle exec #{project_path}/bin/git-pretty-accept --no-edit master"
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
    repo = TestRepo.new(project_path, tmp_path)

    Given 'I have a local repo tracking a remote repo' do
      repo.build
    end

    And 'the local repo has a .git-pretty-accept-template.txt' do
      repo.our.add_merge_message_template_file merge_message
    end

    And 'I have a PR branch' do
      repo.our.add_branch pr_branch
    end

    And 'the current branch is master' do
      repo.our.branch('master').checkout
    end

    When 'I run `git pretty-accept PR_BRANCH`' do
      repo.git_pretty_accept pr_branch
    end

    Then 'I should see that the .git-pretty-accept-template.txt is the content of
      the merge message' do
      expect(repo.our.log[0].message).to eq(merge_message)
    end
  end

  Steps "should be able to use a .git-pretty-accept-template.txt with an apostrophe" do
    merge_message = "hello apostrophe (')"
    repo = TestRepo.new(project_path, tmp_path)

    Given 'I have a local repo tracking a remote repo' do
      repo.build
    end

    And 'the local repo has a .git-pretty-accept-template.txt' do
      repo.our.add_merge_message_template_file merge_message
    end

    And 'I have a PR branch' do
      repo.our.add_branch pr_branch
    end

    And 'the current branch is master' do
      repo.our.branch('master').checkout
    end

    When 'I run `git pretty-accept PR_BRANCH`' do
      repo.git_pretty_accept pr_branch
    end

    Then 'I should see that the .git-pretty-accept-template.txt is the content of
      the merge message' do
      expect(repo.our.log[0].message).to eq(merge_message)
    end
  end

  Steps 'should rebase the branch from its remote branch' do
    local_pr_message = 'local-pr-branch-change.txt'
    remote_pr_message = 'remote-pr-branch-change.txt'

    remote_repo = nil
    local_repo = nil
    other_repo = nil

    Given 'I have a local repo tracking a remote repo' do
      remote_repo = RemoteRepo.new(project_path, remote_path)
      local_repo = LocalRepo.new(project_path, our_path, remote_repo)
      local_repo.add_initial_commit
    end

    And 'I have a PR branch tracking a remote PR branch' do
      other_repo = LocalRepo.new(project_path, their_path, remote_repo)
      other_repo.create_branch pr_branch
      local_repo.track pr_branch
    end

    And 'both local and remote PR branch have been updated' do
      local_repo.commit_some_change local_pr_message

      other_repo.checkout pr_branch
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
      expect(local_repo.git.log[2].parents.size).to eq(1)

      expect(local_repo.git.log[3].parents.size).to eq(0)
    end
  end
end
