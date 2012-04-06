require 'rubygems'
require 'bundler'

Bundler.setup

require 'rspec/core'
require 'rspec/core/rake_task'

desc "Run Unit Specs Only"
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = "spec/github_post_receive/**/*_spec.rb"
  spec.rspec_opts = ["--color", "--format", "doc"]
end

task :default => :spec
