module GithubPostReceive
  class Deployment
    include POSIX::Spawn

    attr_reader :project, :remote, :commit_id, :repo
    
    def initialize(project, remote, commit_id)
      App.logger.debug "Initializing deployment for commit #{commit_id}"
      @project = project
      @remote = remote
      @commit_id = commit_id
      @repo = Grit::Repo.init(File.join(@project.path, @commit_id))
    end

    def clone
      App.logger.debug "Adding #{@remote} as 'origin'"
      @repo.remote_add('origin', @remote)
      App.logger.debug "Fetching #{@remote}"
      @repo.remote_fetch('origin')
    end

    def checkout
      @repo.git.checkout({:raise => true,
                           :base => false,
                           :chdir => @repo.working_dir}, @commit_id)
    end

    def run
      return true if (@project.cmd.nil? || @project.cmd.empty?)
      process = Child.new(@project.cmd, :chdir => @repo.working_dir)
      raise process.err unless process.status.success?
      return true
    rescue => e
      App.logger.error "Project command (#{@project.cmd}) failed: #{e.message}"
      return false
    end

    def deploy
      clone
      checkout
      run
    end
  end
end
