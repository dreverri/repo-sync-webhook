require 'rubygems'
require 'bundler'

Bundler.setup

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'github_post_receive'
GithubPostReceive::App.load_config("config/projects.yml")
run GithubPostReceive::App
