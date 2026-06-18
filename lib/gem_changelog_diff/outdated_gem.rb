# frozen_string_literal: true

module GemChangelogDiff
  # Immutable value object representing a gem with an available update.
  # @!attribute [r] name
  #   @return [String] the gem name
  # @!attribute [r] current_version
  #   @return [String] the currently locked version
  # @!attribute [r] newest_version
  #   @return [String] the latest available version
  OutdatedGem = Data.define(:name, :current_version, :newest_version)
end
