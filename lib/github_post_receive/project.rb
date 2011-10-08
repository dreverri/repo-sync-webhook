module GithubPostReceive
  class Project
    attr_accessor :path, :name, :branch, :cmd, :token, :timeout
    
    def initialize(path, options = {})
      @path = path
      @name = options['name']
      @branch = options['branch']
      @cmd = options['cmd']
      @token = options['token']
      @timeout = options['timeout'] || false
    end

    def match?(payload)
      name == payload.name &&
        branch == payload.branch &&
        (token.nil? || token == payload.token)
    end

    def link_path
      File.join(@path, 'current')
    end
    
    def deploy(remote, commit_id, async=false)
      # Prepare deployment before starting work in the background in
      # order to prevent a race condition between multiple
      # deployments. This assumes the starting process (e.g. a Sinatra
      # application) maintains a lock per project directory
      deployment = prepare(remote, commit_id)
      thread = Thread.new { really_deploy(deployment) }
      thread.join unless async
    end

    def prepare(remote, commit_id)
      Deployment.new(self, remote, commit_id)
    end

    def really_deploy(deployment)
      new_path = deployment.repo.working_dir
      if deployment.deploy
        if File.symlink?(link_path)
          old_path = File.readlink(link_path)
          File.unlink(link_path)
          File.symlink(new_path, link_path)
          FileUtils.rm_rf(old_path)
        else
          File.symlink(new_path, link_path)
        end
      else
        FileUtils.rm_rf(new_path)
      end
    end
  end
end
