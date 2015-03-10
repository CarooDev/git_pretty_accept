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
        options[:autosquash] = true if options[:autosquash].nil?

        Transaction.new(branch, options).call
      end
    end

    description "Accept pull requests, the pretty way"

    on "--[no-]edit", "Edit merge message before committing. (Default: --edit)"
    on "--[no-]autosquash", "Toggle autosquash when rebasing. (Default: --autosquash)"

    arg :branch

    version GitPrettyAccept::VERSION

    use_log_level_option
  end
end
