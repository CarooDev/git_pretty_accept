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

      commands.each do |command|
        puts "\n#{command}"
        system command
      end
    end

    description "Accept pull requests, the pretty way"

    on "--[no-]edit", "Edit merge message before committing. (Default: --edit)"

    arg :branch

    version GitPrettyAccept::VERSION

    use_log_level_option
  end
end
