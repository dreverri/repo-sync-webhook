module GithubPostReceive
  class Payload
    attr_reader :name, :branch, :commit_id, :url, :token

    def self.from_params(params)
      payload = JSON.parse(params[:payload])
      new(payload['repository']['name'],
          payload['ref'].split('/').last,
          payload['after'],
          payload['repository']['url'],
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
