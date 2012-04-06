require 'rubygems'
require 'bundler'

Bundler.setup

require 'rspec'
require 'rack/test'

# Set's the appropriate server settings for Ripple
ENV['RACK_ENV'] = 'test'

# Application
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '../lib'))
require 'github_post_receive'

# Test helpers
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'support/rspec'
