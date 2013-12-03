class TestRepo
  class LocalRepo < SimpleDelegator
    def add_initial_commit
      File.open("#{path}/readme.txt", 'w') { |f| f.write('readme') }
      File.open("#{path}/.gitignore", 'w') do |f|
        f.write('.git-pretty-accept-template.txt')
      end

      add all: true
      commit 'Initial commit.'
      push
    end

    def add_branch(branch)
      branch(branch).checkout
      File.open("#{path}/changelog.txt", 'w') { |f| f.write('changelog') }
      add all: true
      commit 'Add changelog'
      push remote('origin'), branch
    end

    def add_merge_message_template_file(message)
      File.open("#{path}/.git-pretty-accept-template.txt", 'w') do |file|
        file.write message
      end
    end

    def path
      @path ||= dir.path
    end
  end
end
