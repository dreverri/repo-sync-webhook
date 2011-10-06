module GithubPostReceive
  class Payload
    attr_reader :name, :branch, :commit_id, :url, :token

    def self.from_params(params)
      payload = JSON.parse(params[:payload])
      if payload['repository']['private']
        owner_name = payload['repository']['owner']['name']
        repo_name = payload['repository']['name']
        url = "git@github.com:/#{owner_name}/#{repo_name}.git"
      else
        url = payload['repository']['url']
      end
      new(payload['repository']['name'],
          payload['ref'].split('/').last,
          payload['after'],
          url,
          params[:token])
    end
    
    def initialize(name, branch, commit_id, url, token=nil)
      @name = name
      @branch = branch
      @commit_id = commit_id
      @url = url
      @token = token
    end
  end
end
