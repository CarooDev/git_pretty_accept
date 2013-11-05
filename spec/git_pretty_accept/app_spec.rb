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
        `#{project_path}/bin/git-pretty-accept --no-edit #{pr_branch}`
        expect($CHILD_STATUS.exitstatus).to eq(0)
      end
    end

    Then 'it should rebase the PR_BRANCH before merging to master' do
      expect(our.log.size).to eq(4)

      expect(our.log[0].message).to eq("Merge branch 'pr_branch'")
      expect(our.log[0].parents.size).to eq(2)

      expect(our.log[1].message).to eq('Add changelog')
      expect(our.log[1].parents.size).to eq(1)

      expect(our.log[2].message).to eq('Update readme')
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
end
