# frozen_string_literal: true

require "tty-prompt"

module GemChangelogDiff
  # Presents a multi-select prompt for choosing which gems to check.
  class Interactive
    def initialize(gems:)
      @gems = gems
    end

    # Displays the selection prompt and returns chosen gems.
    # @return [Array<OutdatedGem>]
    def select
      prompt = TTY::Prompt.new
      prompt.multi_select("Select gems to check:",
                          per_page: 15, help: "(Space to select, Enter to confirm)") do |menu|
        @gems.each do |gem|
          menu.choice "#{gem.name} (#{gem.current_version} → #{gem.newest_version})", gem
        end
      end
    end
  end
end
