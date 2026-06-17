# frozen_string_literal: true

require "bundler/gem_tasks"
require "bundler/audit/task"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new
Bundler::Audit::Task.new

task default: ["bundle:audit:update", "bundle:audit:check", :rubocop, :spec]
