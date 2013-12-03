class TestRepo
  attr_reader :project_path, :tmp_path

  def initialize(project_path, tmp_path)
    @project_path = project_path
    @tmp_path = tmp_path
  end

  def build
    Git.init remote_path, bare: true

    # Add initial commit. Otherwise, `our.branch(pr_branch)`
    # below won't be able to create a new branch.

    our.add_initial_commit
  end

  def our
    return @our if @our

    Git.clone remote_path, our_path
    @our = LocalRepo.new(Git.open(our_path))
  end

  def our_path
    "#{tmp_path}/our"
  end

  def remote_path
    "#{tmp_path}/remote"
  end

  def git_pretty_accept(branch)
    FileUtils.cd(our_path) do
      puts `bundle exec #{project_path}/bin/git-pretty-accept --no-edit #{branch}`
    end
  end
end
