module Rebuild
  module Printer
    class RbldPrinter
      def self.error(msg)
        puts
        puts "    ERROR: #{msg}".light_red
        puts
      end

      def self.warning(msg)
         puts "WARNING: #{msg}".light_yellow
      end

      def self.progress(msg)
        puts
        puts "#{msg}".light_green
      end
    end

    def rbld_print
      RbldPrinter
    end
  end
end

include Rebuild::Printer
