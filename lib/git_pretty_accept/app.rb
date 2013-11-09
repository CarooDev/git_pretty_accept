module GitPrettyAccept
  class App
    include Methadone::Main
    include Methadone::CLILogging

    main do |branch|
      options[:edit] = true if options[:edit].nil?

      our = Git.open('.')
      source_branch = our.branches.find(&:current).to_s

      commands = [
        "git pull",
        "git checkout #{branch}",
        "git rebase #{source_branch}",
        "git checkout #{source_branch}",
        "git merge --no-ff #{options[:edit] ? '--edit' : '--no-edit'} #{branch}",
        "git push",
        "git branch -d #{branch}",
        "git push origin :#{branch}"
      ]

      commands.each_with_index do |command, i|
        puts "\n#{command}"
        unless system(command)
          puts "\nDue to the error above, the following commands were not executed: "
          puts commands[i + 1, commands.size].join("\n")
          exit!
        end
      end
    end

    description "Accept pull requests, the pretty way"

    on "--[no-]edit", "Edit merge message before committing. (Default: --edit)"

    arg :branch

    version GitPrettyAccept::VERSION

    use_log_level_option
  end
end
