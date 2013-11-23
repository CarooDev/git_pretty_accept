module GitPrettyAccept
  class App
    include Methadone::Main
    include Methadone::CLILogging

    main do |branch|
      if branch == 'master'
        error "You're trying to accept master as a pull request branch. " +
          "Please checkout to master instead and accept this branch " +
          "from there."
        exit!
      else
        options[:edit] = true if options[:edit].nil?

        our = Git.open('.')
        source_branch = our.branches.find(&:current).to_s

        commands = [
          "git pull origin #{source_branch}",
          "git checkout #{branch}",
          "git rebase origin/#{source_branch}",
          "git push --force origin #{branch}",
          "git checkout #{source_branch}",
          "git merge --no-ff #{options[:edit] ? '--edit' : '--no-edit'} #{branch}",
          "git push origin #{source_branch}",
          "git branch -D #{branch}",
          "git push origin :#{branch}"
        ]

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
    end

    description "Accept pull requests, the pretty way"

    on "--[no-]edit", "Edit merge message before committing. (Default: --edit)"

    arg :branch

    version GitPrettyAccept::VERSION

    use_log_level_option
  end
end
