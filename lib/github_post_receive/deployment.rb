module GithubPostReceive
  class AlreadyDeployed < StandardError; end
  class Deployment
    include POSIX::Spawn

    attr_reader :project, :remote, :commit_id, :repo
    
    def initialize(project, remote, commit_id)
      App.logger.debug "Initializing deployment for commit #{commit_id}"
      @project = project
      @remote = remote
      @commit_id = commit_id
      path = File.join(@project.path, @commit_id)
      raise AlreadyDeployed.new(path) if File.exists? path
      @repo = Grit::Repo.init(path)
    end

    def clone
      options = {:raise => true, :timeout => @project.timeout}
      App.logger.debug "Adding #{@remote} as 'origin'"
      @repo.git.remote(options, 'add', 'origin', @remote)
      App.logger.debug "Fetching #{@remote}"
      @repo.git.fetch(options, 'origin')
    end

    def checkout
      @repo.git.checkout({:raise => true,
                           :timeout => @project.timeout,
                           :base => false,
                           :chdir => @repo.working_dir}, @commit_id)
    end

    def run
      return true if (@project.cmd.nil? || @project.cmd.empty?)
      process = Child.new(@project.cmd, :chdir => @repo.working_dir)
      raise process.err unless process.status.success?
      return true
    end

    def deploy
      clone
      checkout
      run
    rescue => e
      App.logger.error "Deploy failed [#{@project.name}][#{@project.path}][#{@commit_id}]: #{e.inspect}"
      return false
    end
  end
end
