#!/usr/bin/env ruby

module Rebuild
  class RbldListCommand < Command
    def initialize
      @usage = "list [OPTIONS]"
      @description = "List local environments"
    end

    run_prints :all
  end
end
