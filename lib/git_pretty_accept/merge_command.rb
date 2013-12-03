module GitPrettyAccept
  class MergeCommand
    MESSAGE_TEMPLATE_FILENAME = '.git-pretty-accept-template.txt'
    attr_reader :branch, :let_user_edit_message

    def initialize(branch, let_user_edit_message)
      @branch = branch
      @let_user_edit_message = let_user_edit_message
    end

    def merge_message
      if File.exists?(MESSAGE_TEMPLATE_FILENAME)
        File.read(MESSAGE_TEMPLATE_FILENAME)
      end
    end

    def to_s
      [
        "git merge",
        "--no-ff",
        let_user_edit_message ? '--edit' : '--no-edit',
        branch,
        merge_message && "--message '#{merge_message}'"
      ].join(' ')
    end
  end
end
