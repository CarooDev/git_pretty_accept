module GitPrettyAccept
  class Transaction
    include Methadone::CLILogging

    attr_reader :branch, :let_user_edit_message

    def initialize(branch, let_user_edit_message = true)
      @branch = branch
      @let_user_edit_message = let_user_edit_message
    end

    def commands
      [
        "git fetch origin",
        "git rebase origin/#{source_branch}",
        "git checkout #{branch}",
        "git rebase origin/#{branch}",
        "git rebase origin/#{source_branch}",
        "git push --force origin #{branch}",
        "git checkout #{source_branch}",
        MergeCommand.new(branch, let_user_edit_message).to_s,
        "git push origin #{source_branch}",
        "git branch -d #{branch}",
        "git push origin :#{branch}"
      ]
    end

    def call
      commands.each_with_index do |command, i|
        info "\n#{command}"
        unless system(command)
          error "\nDue to the error above, " +
            "the following commands were not executed: " +
            commands[i + 1, commands.size].join("\n")
          exit!
        end
      end
    end

    def source_branch
      return @source_branch if @source_branch
      our = Git.open('.')
      @source_branch = our.branches.find(&:current).to_s
    end
  end
end
