# frozen_string_literal: true

# rubocop:disable Metrics/LineLength
module Commands
  class Command < Dry::CLI::Command
  end

  module Assets
    class Precompile < Dry::CLI::Command
      desc 'Precompile assets for deployment'

      example [
        'FOO_ENV=production # Precompile assets for production environment'
      ]

      def call(*); end
    end
  end

  class Console < Dry::CLI::Command
    desc 'Starts Foo console'
    option :engine, desc: 'Force a console engine', values: %w[irb pry ripl]

    example [
      '             # Uses the bundled engine',
      '--engine=pry # Force to use Pry'
    ]

    def call(engine: nil, **)
      puts "console - engine: #{engine}"
    end
  end

  module DB
    class Apply < Dry::CLI::Command
      desc 'Migrate, dump the SQL schema, and delete the migrations (experimental)'

      def call(*); end
    end

    class Console < Dry::CLI::Command
      desc 'Starts a database console'

      def call(*); end
    end

    class Create < Dry::CLI::Command
      desc 'Create the database (only for development/test)'

      def call(*); end
    end

    class Drop < Dry::CLI::Command
      desc 'Drop the database (only for development/test)'

      def call(*); end
    end

    class Migrate < Dry::CLI::Command
      desc 'Migrate the database'
      argument :version, desc: 'The target version of the migration (see `foo db version`)'

      example [
        '               # Migrate to the last version',
        '20170721120747 # Migrate to a specific version'
      ]

      def call(*); end
    end

    class Prepare < Dry::CLI::Command
      desc 'Drop, create, and migrate the database (only for development/test)'

      def call(*); end
    end

    class Version < Dry::CLI::Command
      desc 'Print the current migrated version'

      def call(*); end
    end

    class Rollback < Dry::CLI::Command
      desc 'Rollback the database'

      argument :steps, desc: 'Number of versions to rollback', default: 1

      def call(steps:, **)
        puts steps
      end
    end
  end

  module Destroy
    class Action < Dry::CLI::Command
      desc 'Destroy an action from app'

      example [
        'web home#index    # Basic usage',
        'admin users#index # Destroy from `admin` app'
      ]

      argument :app,    required: true, desc: 'The application name (eg. `web`)'
      argument :action, required: true, desc: 'The action name (eg. `home#index`)'

      def call(app:, action:, **)
        puts "destroy action - app: #{app}, action: #{action}"
      end
    end

    class App < Dry::CLI::Command
      desc 'Destroy an app'

      argument :app, required: true, desc: 'The application name (eg. `web`)'

      example [
        'admin # Destroy `admin` app'
      ]

      def call(*); end
    end

    class Mailer < Dry::CLI::Command
      desc 'Destroy a mailer'

      argument :mailer, required: true, desc: 'The mailer name (eg. `welcome`)'

      example [
        'welcome # Destroy `WelcomeMailer` mailer'
      ]

      def call(*); end
    end

    class Migration < Dry::CLI::Command
      desc 'Destroy a migration'

      argument :migration, required: true, desc: 'The migration name (eg. `create_users`)'

      example [
        'create_users # Destroy `db/migrations/20170721120747_create_users.rb`'
      ]

      def call(*); end
    end

    class Model < Dry::CLI::Command
      desc 'Destroy a model'

      argument :model, required: true, desc: 'The model name (eg. `user`)'

      example [
        'user # Destroy `User` entity and `UserRepository` repository'
      ]

      def call(*); end
    end
  end

  module Generate
    class Action < Dry::CLI::Command
      desc 'Generate an action for app'

      example [
        'web home#index                    # Basic usage',
        'admin home#index                  # Generate for `admin` app',
        'web home#index --url=/            # Specify URL',
        'web sessions#destroy --method=GET # Specify HTTP method',
        'web books#create --skip-view      # Skip view and template'
      ]

      argument :app,    required: true, desc: 'The application name (eg. `web`)'
      argument :action, required: true, desc: 'The action name (eg. `home#index`)'

      option :url, desc: 'The action URL'
      option :method, desc: 'The action HTTP method'
      option :skip_view, type: :boolean, default: false, desc: 'Skip view and template'

      def call(app:, action:, **options)
        puts "generate action - app: #{app}, action: #{action}, options: #{options.inspect}"
      end
    end

    class App < Dry::CLI::Command
      desc 'Generate an app'

      argument :app, required: true, desc: 'The application name (eg. `web`)'
      option :application_base_url, desc: 'The app base URL (eg. `/api/v1`)'

      example [
        'admin                              # Generate `admin` app',
        'api --application-base-url=/api/v1 # Generate `api` app and mount at `/api/v1`'
      ]

      def call(*); end
    end

    class Mailer < Dry::CLI::Command
      desc 'Generate a mailer'

      argument :mailer, required: true, desc: 'The mailer name (eg. `welcome`)'

      option :from,    desc: 'The default `from` field of the mail'
      option :to,      desc: 'The default `to` field of the mail'
      option :subject, desc: 'The mail subject'

      example [
        'welcome                                         # Basic usage',
        'welcome --from="noreply@example.com"            # Generate with default `from` value',
        'announcement --to="users@example.com"           # Generate with default `to` value',
        'forgot_password --subject="Your password reset" # Generate with default `subject`'
      ]

      def call(*); end
    end

    class Migration < Dry::CLI::Command
      desc 'Generate a migration'

      argument :migration, required: true, desc: 'The migration name (eg. `create_users`)'

      example [
        'create_users # Generate `db/migrations/20170721120747_create_users.rb`'
      ]

      def call(*); end
    end

    class Model < Dry::CLI::Command
      desc 'Generate a model'

      argument :model, required: true, desc: 'Model name (eg. `user`)'
      option :skip_migration, type: :boolean, default: false, desc: 'Skip migration'

      example [
        'user                  # Generate `User` entity, `UserRepository` repository, and the migration',
        'user --skip-migration # Generate `User` entity and `UserRepository` repository'
      ]

      def call(model:, **)
        puts "generate model - model: #{model}"
      end
    end

    class Secret < Dry::CLI::Command
      desc 'Generate session secret'

      argument :app, desc: 'The application name (eg. `web`)'

      example [
        '    # Prints secret (eg. `6fad60e21f3f6bfcaf8e56cdb0f835d644b4892c3badc58328126812429bf073`)',
        'web # Prints session secret (eg. `WEB_SESSIONS_SECRET=6fad60e21f3f6bfcaf8e56cdb0f835d644b4892c3badc58328126812429bf073`)'
      ]

      def call(app: nil, **)
        puts "generate secret - app: #{app}"
      end
    end
  end

  class New < Dry::CLI::Command
    desc 'Generate a new Foo project'
    argument :project, required: true

    option :database,             desc: 'Database (sqlite/postgres/mysql)', default: 'sqlite', aliases: ['-d', '--db']
    option :application_name,     desc: 'App name', default: 'web'
    option :application_base_url, desc: 'App base URL', default: '/'
    option :template,             desc: 'Template engine (erb/haml/slim)', default: 'erb'
    option :test,                 desc: 'Project testing framework (minitest/rspec)', default: 'minitest'
    option :foo_head,             desc: 'Use Foo HEAD (true/false)', type: :boolean, default: false

    example [
      'bookshelf                     # Basic usage',
      'bookshelf --test=rspec        # Setup RSpec testing framework',
      'bookshelf --database=postgres # Setup Postgres database',
      'bookshelf --template=slim     # Setup Slim template engine',
      'bookshelf --foo-head          # Use Foo HEAD'
    ]

    def call(project:, **)
      puts "new - project: #{project}"
    end
  end

  class Routes < Dry::CLI::Command
    desc 'Print routes'

    def call(*); end
  end

  class Server < Dry::CLI::Command
    desc 'Start Foo server (only for development)'

    option :server,         desc: 'Force a server engine (eg, webrick, puma, thin, etc..)'
    option :host,           desc: 'The host address to bind to'
    option :port,           desc: 'The port to run the server on', aliases: ['-p', 'p', '--p']
    option :debug,          desc: 'Turn on debug output'
    option :warn,           desc: 'Turn on warnings'
    option :daemonize,      desc: 'Daemonize the server'
    option :pid,            desc: 'Path to write a pid file after daemonize'
    option :code_reloading, desc: 'Code reloading', type: :boolean, default: true
    option :deps,           desc: 'List of extra dependencies', type: :array, default: %w[dep1 dep2]

    example [
      '                    # Basic usage (it uses the bundled server engine)',
      '--server=webrick    # Force `webrick` server engine',
      '--host=0.0.0.0      # Bind to a host',
      '--port=2306         # Bind to a port',
      '--no-code-reloading # Disable code reloading'
    ]

    def call(**options)
      puts "server - #{options.inspect}"
    end
  end

  class Version < Dry::CLI::Command
    desc 'Print Foo version'

    def call(*)
      puts 'v1.0.0'
    end
  end

  class Exec < Dry::CLI::Command
    desc 'Execute a task'

    argument :task, desc: 'Task to execute', type: :string, required: true
    argument :dirs, desc: 'Directories',     type: :array,  required: false

    def call(task:, dirs: [], **)
      puts "exec - Task: #{task} - Directories: #{dirs.inspect}"
    end
  end

  class Hello < Dry::CLI::Command
    def call(*)
      raise NotImplementedError
    end
  end

  class Greeting < Dry::CLI::Command
    argument :response, default: 'Hello World'

    option :person

    def call(response:, **options)
      puts "response: #{response}, person: #{options[:person]}"
    end
  end

  class VariadicArguments < Dry::CLI::Command
    desc 'accept multiple arguments at the end of the command'

    def call(**options)
      puts "Unused Arguments: #{options[:args].join(', ')}"
    end
  end

  class MandatoryAndVariadicArguments < Dry::CLI::Command
    desc 'require one command and accept multiple unused arguments'

    argument :first, desc: 'mandatory first argument', required: true

    def call(first:, **options)
      puts "first: #{first}"
      puts "Unused Arguments: #{options[:args].join(', ')}"
    end
  end

  class MandatoryOptionsAndVariadicArguments < Dry::CLI::Command
    desc 'require one command, accept options and multiple unused arguments'

    argument :first, desc: 'mandatory first argument', required: true
    option :url, desc: 'The action URL'
    option :method, desc: 'The action HTTP method'

    def call(first:, **options)
      puts "first: #{first}"
      puts "url: #{options[:url]}"
      puts "method: #{options[:method]}"
      puts "Unused Arguments: #{options[:args].join(', ')}"
    end
  end

  class OptionsWithAliases < Dry::CLI::Command
    desc 'Accepts options with aliases'

    option :url, desc: 'The action URL', aliases: %w[-u u --u]
    option :flag, desc: 'The flag', type: :boolean, aliases: %w[f]
    option :opt, desc: 'The opt', type: :boolean, aliases: %w[o], default: false

    def call(**options)
      puts "options with aliases - #{options.inspect}"
    end
  end

  module Sub
    class Command < Dry::CLI::Command
      def call(*)
        raise NotImplementedError
      end
    end
  end

  class RootCommand < Dry::CLI::Command
    desc 'Root command with arguments and subcommands'
    argument :root_command_argument, desc: 'Root command argument', required: true
    option :root_command_option, desc: 'Root command option'

    def call(**params)
      puts "I'm a root-command argument:#{params[:root_command_argument]}"
      puts "I'm a root-command option:#{params[:root_command_option]}"
    end
  end

  module RootCommands
    class SubCommand < Dry::CLI::Command
      desc 'Root command sub command'
      argument :root_command_sub_command_argument, desc: 'Root command sub command argument', required: true
      option :root_command_sub_command_option, desc: 'Root command sub command option'

      def call(**params)
        puts "I'm a root-command sub-command argument:#{params[:root_command_sub_command_argument]}"
        puts "I'm a root-command sub-command option:#{params[:root_command_sub_command_option]}"
      end
    end

    class SubCommand2 < Dry::CLI::Command
      desc 'Root command sub command'
      argument :root_command_sub_command_argument, desc: 'Root command sub command argument', required: true
      option :root_command_sub_command_option, desc: 'Root command sub command option'

      def call(**params)
        puts "I'm a root-command sub-command argument:#{params[:root_command_sub_command_argument]}"
        puts "I'm a root-command sub-command option:#{params[:root_command_sub_command_option]}"
      end
    end
  end
end

module Webpack
  module CLI
    class Generate < Dry::CLI::Command
      desc 'Generate webpack configuration'

      option :apps, desc: 'Generate webpack apps', type: :array

      def call(apps: [], **)
        puts "generate webpack. Apps: #{apps}"
      end
    end

    class Hello < Dry::CLI::Command
      desc 'Print a greeting'

      def call(*)
        puts 'hello from webpack'
      end
    end

    class SubCommand < Dry::CLI::Command
      desc 'Override a subcommand'

      def call(**)
        puts 'override from webpack'
      end
    end

    class CallbacksCommand < Dry::CLI::Command
      desc 'Command with callbacks'
      argument :dir, required: true
      option :url

      def call(dir:, url: nil, **)
        puts "dir: #{dir}, url: #{url.inspect}"
      end
    end
  end
end

module Callbacks
  class BeforeClass
    def call(args)
      puts "before callback (class), #{count(args)} arg(s): #{args.inspect}"
    end

    private

    def count(args)
      args.count
    end
  end

  class AfterClass
    def call(args)
      puts "after callback (class), #{count(args)} arg(s): #{args.inspect}"
    end

    private

    def count(args)
      args.count
    end
  end

  class Before
    def call(args)
      puts "before callback (object), #{count(args)} arg(s): #{args.inspect}"
    end

    private

    def count(args)
      args.count
    end
  end

  class After
    def call(args)
      puts "after callback (object), #{count(args)} arg(s): #{args.inspect}"
    end

    private

    def count(args)
      args.count
    end
  end
end
# rubocop:enable Metrics/LineLength
