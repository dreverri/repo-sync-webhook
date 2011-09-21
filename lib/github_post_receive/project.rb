module GithubPostReceive
  class Project
    attr_reader :path, :name, :branch, :cmd, :token
    
    def initialize(path, options = {})
      @path = path
      @name = options['name']
      @branch = options['branch']
      @cmd = options['cmd']
      @token = options['token']
    end

    def match?(payload)
      name == payload.name &&
        branch == payload.branch &&
        (token.nil? || token == payload.token)
    end

    def link_path
      File.join(@path, 'current')
    end
    
    def deploy(remote, commit_id)
      deployment = Deployment.new(self, remote, commit_id)
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
