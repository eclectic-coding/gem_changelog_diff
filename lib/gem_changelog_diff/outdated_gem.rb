# frozen_string_literal: true

module GemChangelogDiff
  OutdatedGem = Data.define(:name, :current_version, :newest_version)
end
