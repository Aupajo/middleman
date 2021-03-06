module Padrino
  ##
  # Runs the Padrino apps as a self-hosted server using:
  # thin, mongrel, or WEBrick in that order.
  #
  # @example
  #   Padrino.run! # with these defaults => host: "127.0.0.1", port: "3000", adapter: the first found
  #   Padrino.run!("0.0.0.0", "4000", "mongrel") # use => host: "0.0.0.0", port: "4000", adapter: "mongrel"
  #
  def self.run!(options={})
    Padrino.load!
    Server.start(Padrino.application, options)
  end

  ##
  # This module builds a Padrino server to run the project based on available handlers.
  #
  class Server < Rack::Server
    # Server Handlers
    Handlers = [:thin, :puma, :mongrel, :trinidad, :webrick]

    # Starts the application on the available server with specified options.
    def self.start(app, opts={})
      options = {}.merge(opts) # We use a standard hash instead of Middleman::Util::HashWithIndifferentAccess
      options.symbolize_keys!
      options[:Host] = options.delete(:host) || '127.0.0.1'
      options[:Port] = options.delete(:port) || 3000
      options[:AccessLog] = []
      if options[:daemonize]
        options[:pid] = File.expand_path(options[:pid].blank? ? 'tmp/pids/server.pid' : opts[:pid])
        FileUtils.mkdir_p(File.dirname(options[:pid]))
      end
      options[:server] = detect_rack_handler if options[:server].blank?
      if options[:options].is_a?(Array)
        parsed_server_options = options.delete(:options).map { |opt| opt.split('=', 2) }.flatten
        server_options = Hash[*parsed_server_options].symbolize_keys!
        options.merge!(server_options)
      end
      new(options, app).start
    end

    def initialize(options, app)
      @options, @app = options, app
    end

    # Starts the application on the available server with specified options.
    def start
      puts "=> Padrino/#{Padrino.version} has taken the stage #{Padrino.env} at http://#{options[:Host]}:#{options[:Port]}"
      [:INT, :TERM].each { |sig| trap(sig) { exit } }
      super
    ensure
      puts "<= Padrino leaves the gun, takes the cannoli" unless options[:daemonize]
    end

    # The application the server will run.
    def app
      @app
    end
    alias :wrapped_app :app

    def options
      @options
    end

    private
    # Detects the supported handler to use.
    #
    # @example
    #   detect_rack_handler => <ThinHandler>
    #
    def self.detect_rack_handler
      Handlers.each do |handler|
        begin
          return handler if Rack::Handler.get(handler.to_s.downcase)
        rescue LoadError
        rescue NameError
        end
      end
      fail "Server handler (#{Handlers.join(', ')}) not found."
    end
  end
end
