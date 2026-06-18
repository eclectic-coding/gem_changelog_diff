# frozen_string_literal: true

require_relative "lib/gem_changelog_diff/version"

Gem::Specification.new do |spec|
  spec.name = "gem_changelog_diff"
  spec.version = GemChangelogDiff::VERSION
  spec.authors = ["Chuck Smith"]
  spec.email = ["eclectic-coding@users.noreply.github.com"]

  spec.summary = "Show changelog diffs for outdated gems before you bundle update."
  spec.description = "CLI that shows you the changelog diff for each gem before you bundle update, " \
                     "pulled from GitHub releases."
  spec.homepage = "https://github.com/eclectic-coding/gem_changelog_diff"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"
  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/eclectic-coding/gem_changelog_diff"
  spec.metadata["changelog_uri"] = "https://github.com/eclectic-coding/gem_changelog_diff/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "https://rubydoc.info/gems/gem_changelog_diff"

  spec.metadata["rubygems_mfa_required"] = "true"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", "~> 1.0"
  spec.add_dependency "tty-color", "~> 0.6"
  spec.add_dependency "tty-prompt", "~> 0.23"
  spec.add_dependency "tty-spinner", "~> 0.9"
end
