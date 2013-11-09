module GitPrettyAccept
  class App
    include Methadone::Main
    include Methadone::CLILogging

    main do |branch|
      merge_message = 'Merge add_changelog branch'
      our = Git.open('.')
      source_branch = our.branch.to_s
      our.pull
      our.branch(branch).checkout
      `git rebase #{source_branch}`
      our.branch(source_branch).checkout
      `git merge --no-ff --message "#{merge_message}" #{branch}`
      our.push
      our.branch(branch).delete
      our.push our.remote('origin'), ":#{branch}"
    end

    # supplemental methods here

    # Declare command-line interface here

    # description "one line description of your app"
    #
    # Accept flags via:
    # on("--flag VAL","Some flag")
    # options[flag] will contain VAL
    #
    # Specify switches via:
    # on("--[no-]switch","Some switch")
    #
    # Or, just call OptionParser methods on opts
    #
    # Require an argument
    # arg :some_arg
    #
    # # Make an argument optional
    # arg :optional_arg, :optional

    version GitPrettyAccept::VERSION

    use_log_level_option
  end
end
