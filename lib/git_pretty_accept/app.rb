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
        Transaction.new(branch, options[:edit]).call
      end
    end

    description "Accept pull requests, the pretty way"

    on "--[no-]edit", "Edit merge message before committing. (Default: --edit)"

    arg :branch

    version GitPrettyAccept::VERSION

    use_log_level_option
  end
end
