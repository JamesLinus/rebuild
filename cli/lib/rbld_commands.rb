#!/usr/bin/env ruby

module Rebuild
  class CommandError < RuntimeError
    def initialize(errcode)
      @code = errcode
    end

    attr_reader :code
  end

  class Commands
    extend Enumerable

    private

    COMMAND_PREFIX="re-build-cmd-"

    def self.script_path(name)
      File.join( File.dirname( __FILE__ ),
                 "..",
                 "libexec",
                 COMMAND_PREFIX + name )
    end

    def self.list_scripts
      commands_list = Dir[self.script_path( '*' )]
      commands_list.reject {|f| File.directory? f}
    end

    def self.list_commands
      self.list_scripts.map { |script| script.sub( /^.*#{COMMAND_PREFIX}/, '' )}
    end

    def self.deduce_cmd_name(handler_class)
      match = handler_class.name.match(/Rbld(.*)Command/)
      return nil unless match
      match.captures[0].downcase
    end

    def self.get_cmd_handler(command)
      @handler_classes.each do |klass|
        return klass.new if command == deduce_cmd_name( klass )
      end
      nil
    end

    KNOWN_COMMANDS=self.list_commands
    @handler_classes = []

    public

    def self.register_handler_class(klass)
      unless deduce_cmd_name( klass )
        raise LoadError.new("Failed to bind command handler class #{klass}")
      end

      @handler_classes << klass
    end

    def self.each
      KNOWN_COMMANDS.each { |cmd| yield( cmd ) }
      @handler_classes.each { |klass| yield( deduce_cmd_name( klass ) ) }
    end

    def self.usage(command)
      handler = get_cmd_handler( command )
      return handler.usage if handler

      run(command, ["--help"])
    end

    def self.run(command, parameters)
      handler = get_cmd_handler( command )
      return handler.run(parameters) if handler

      parameters = parameters.join(" ")

      rbld_log.info( "Running #{command}(#{parameters})" )

      unless KNOWN_COMMANDS.include? command
        raise "Unknown command: #{command}"
      end

      system( "#{script_path( command )} #{parameters}" )

      errcode = $?.exitstatus

      rbld_log.info( "Command returned with code #{errcode}" )

      raise CommandError, errcode if errcode != 0
    end
  end

  class Command

    private

    def self.inherited( handler_class )
      Commands.register_handler_class( handler_class )
      rbld_log.info( "Command handler class #{handler_class} registered" )
    end

    def self.legacy_usage_implementation( cmd_name )
      code = %Q{
        def usage
          LegacyCommand.run("#{cmd_name}", ["--help"])
        end
      }
      class_eval( code )
    end

    def self.legacy_run_implementation( cmd_name )
      code = %Q{
        def run(parameters)
          LegacyCommand.run("#{cmd_name}", parameters)
        end
      }
      class_eval( code )
    end
  end

  class LegacyCommand
    private

    COMMAND_PREFIX="re-build-legacy-cmd-"

    def self.script_path(name)
      File.join( File.dirname( __FILE__ ),
                 "..",
                 "libexec",
                 COMMAND_PREFIX + name )
    end

    public

    def self.run(command, parameters)
      parameters = parameters.join(" ")

      rbld_log.info( "Running legacy #{command}(#{parameters})" )

      system( "#{script_path( command )} #{parameters}" )

      errcode = $?.exitstatus

      rbld_log.info( "Legacy command returned with code #{errcode}" )

      raise CommandError, errcode if errcode != 0
    end
  end

  class Main

    def self.usage
      usage_text = <<USAGE
Usage:
  rbld help                Show this help screen
  rbld help COMMAND        Show help for COMMAND
  rbld COMMAND [PARAMS]    Run COMMAND with PARAMS

rebuild: Zero-dependency, reproducible build environments

Commands:

USAGE

      Commands.sort.each { |cmd| usage_text << "  #{cmd}\n"}

      usage_text
    end
  end
end
