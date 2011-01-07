require 'rubygems'
require 'sinatra'
require 'json'
require 'yaml'

# TODO: Make config file configurable
CONFIG = YAML::load_file("config.yml") unless defined? CONFIG

set :lock, true

get '/' do
    'Nothing to see here'
end

post '/notify' do
  process_request(params, CONFIG)
  "Thank you"
end

def process_request(params, config)
  payload = JSON.parse(params[:payload])
  name = payload['repository']['name']
  branch = payload["ref"].split("/").last
  commit_id = payload['after']

  config[:projects].each do |project|
    if project[:name] == name && project[:branch] == branch
      if project[:token].nil? || project[:token] == params[:token]
        puts "Processing #{name}:#{branch}"
        root = project[:root]
        cmd = project[:cmd]
        remote = url(payload, project)

        process_project(root, name, commit_id, remote, cmd)
      else
        puts "The provided token, #{params[:token]}, did not match"
      end
    end
  end
end

def process_project(root, name, commit_id, remote, cmd)
  repo_path = File.join(root, name)
  cache_path = File.join(repo_path, "cache")
  commit_path = File.join(repo_path, commit_id)

  # Mirror repo or fetch updates
  if File.exists?cache_path
    puts "Fetching updates to #{cache_path}"
    fetch(cache_path)
  else
    puts "Mirroring repository #{remote} to #{cache_path}"
    mirror(remote, cache_path)
  end

  # Check out commit
  # What is the least surprising behavior when the commit path already exists?
  unless File.exists?commit_path
    puts "Creating the directory #{commit_path}"
    Dir.mkdir(commit_path)
    puts "Checking out #{commit_id}"
    checkout(cache_path, commit_path, commit_id)

    # Change to commit directory and run cmd
    puts "Running #{cmd}"
    %x[cd #{commit_path} && #{cmd}]
  else
    puts "The directory for this commit already exists: #{commit_path}"
  end
end

def mirror(repo, cache)
  %x[git clone --bare #{repo} #{cache} && (cd #{cache} && git remote add --mirror origin #{repo})]
end

def fetch(cache)
  %x[git --git-dir=#{cache} fetch]
end

def checkout(cache, commit_path, commit_id)
  clone = "git clone #{cache} #{commit_path}"
  checkout_opts = "--git-dir=#{commit_path}/.git --work-tree=#{commit_path}"
  checkout = "git #{checkout_opts} checkout -f #{commit_id}"
  %x[#{clone} && #{checkout}]
end

def url(payload, project)
  url = payload['repository']['url']
  project[:git_url] || url.gsub(/https:\/\//, 'git://') + '.git'
end
