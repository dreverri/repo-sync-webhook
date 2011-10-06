require 'rubygems'
require 'bundler'

Bundler.setup

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'github_post_receive'
GithubPostReceive::App.load_config("config/projects.yml")
if File.exists?("config/logger.yml")
  GithubPostReceive::App.load_logger_config("config/logger.yml")
end
run GithubPostReceive::App
