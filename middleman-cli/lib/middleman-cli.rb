# Setup our load paths
libdir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

# Require Thor since that's what the whole CLI is built around
require 'thor'
require 'thor/group'

# CLI Module
module Middleman

  module Cli

    # The base task from which everything else extends
    class Base < Thor
      class << self
        def start(*args)
          # Change flag to a module
          ARGV.unshift('help') if ARGV.delete('--help')

          # Default command is server
          if ARGV[0] != 'help' && (ARGV.length < 1 || ARGV.first.include?('-'))
            ARGV.unshift('server')
          end

          super
        end
      end

      desc 'version', 'Show version'
      def version
        require 'middleman-core/version'
        say "Middleman #{Middleman::VERSION}"
      end

      # Override the Thor help method to find help for subtasks
      # @param [Symbol, String, nil] meth
      # @param [Boolean] subcommand
      # @return [void]
      def help(meth = nil, subcommand = false)
        if meth && !self.respond_to?(meth)
          klass, task = Thor::Util.find_class_and_task_by_namespace("#{meth}:#{meth}")
          klass.start(['-h', task].compact, :shell => self.shell)
        else
          list = []
          Thor::Util.thor_classes_in(Middleman::Cli).each do |thor_class|
            list += thor_class.printable_tasks(false)
          end
          list.sort!{ |a,b| a[0] <=> b[0] }

          shell.say 'Tasks:'
          shell.print_table(list, :ident => 2, :truncate => true)
          shell.say %(\nSee 'middleman help <command>' for more information on specific command.)
          shell.say
        end
      end

      # Intercept missing methods and search subtasks for them
      # @param [Symbol] meth
      def method_missing(meth, *args)
        meth = meth.to_s

        if self.class.map.has_key?(meth)
          meth = self.class.map[meth]
        end

        klass, task = Thor::Util.find_class_and_task_by_namespace("#{meth}:#{meth}")

        if klass.nil?
          tasks_dir = File.join(Dir.pwd, 'tasks')

          if File.exists?(tasks_dir)
            Dir[File.join(tasks_dir, '**/*_task.rb')].each { |f| require f }
            klass, task = Thor::Util.find_class_and_task_by_namespace("#{meth}:#{meth}")
          end
        end

        if klass.nil?
          raise Thor::Error.new "There's no '#{meth}' command for Middleman. Try 'middleman help' for a list of commands."
        else
          args.unshift(task) if task
          klass.start(args, :shell => self.shell)
        end
      end
    end
  end
end

# Include the core CLI items
require 'middleman-cli/init'
require 'middleman-cli/extension'
require 'middleman-cli/server'
require 'middleman-cli/build'
require 'middleman-cli/console'
