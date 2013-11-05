module GitPrettyAccept
  class App
    include Methadone::Main
    include Methadone::CLILogging

    main do |branch|
      options[:edit] = true if options[:edit].nil?

      our = Git.open('.')
      source_branch = our.branches.find(&:current).to_s
      our.pull
      our.branch(branch).checkout
      `git rebase #{source_branch}`
      our.branch(source_branch).checkout

      # Open git message editor in a separate process so that it will open its
      # own commit message editor.
      system "git merge --no-ff #{options[:edit] ? '--edit' : '--no-edit'} #{branch}"

      our.push
      our.branch(branch).delete
      our.push our.remote('origin'), ":#{branch}"
    end

    description "Accept pull requests, the pretty way"

    on "--[no-]edit", "Edit merge message before committing. (Default: --edit)"

    arg :branch

    version GitPrettyAccept::VERSION

    use_log_level_option
  end
end
