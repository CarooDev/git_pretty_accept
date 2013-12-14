class LocalRepo
  attr_reader :git, :project_path, :path

  def initialize(project_path, path, remote_repo)
    @project_path = project_path
    @path = path
    @remote_repo = remote_repo

    Git.clone remote_repo.path, path
    @git = Git.open(path)
  end

  def add_initial_commit
    File.open("#{path}/readme.txt", 'w') { |f| f.write('readme') }
    File.open("#{path}/.gitignore", 'w') do |f|
      f.write('.git-pretty-accept-template.txt')
    end

    git.add all: true
    git.commit 'Initial commit.'
    git.push
  end

  def add_merge_message_template_file(message)
    File.open("#{path}/.git-pretty-accept-template.txt", 'w') do |file|
      file.write message
    end
  end

  def checkout(branch)
    git.branch(branch).checkout
  end

  def commit_some_change(message)
    File.open("#{path}/#{message}.txt", 'w') { |f| f.write(message) }
    git.add all: true
    git.commit message
  end

  def create_branch(branch)
    git.branch(branch).checkout
    git.push git.remote('origin'), branch
  end

  def git_pretty_accept(branch)
    FileUtils.cd(path) do
      puts `bundle exec #{project_path}/bin/git-pretty-accept --no-edit #{branch}`
    end
  end

  def push_some_change(message)
    commit_some_change message
    git.push git.remote('origin'), git.branches.local.find(&:current)
  end

  def track(branch)
    git.branch(branch).checkout
  end
end
