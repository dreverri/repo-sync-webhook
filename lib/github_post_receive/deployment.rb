module GithubPostReceive
  class Deployment
    include POSIX::Spawn

    attr_reader :project, :remote, :commit_id, :repo
    
    def initialize(project, remote, commit_id)
      @project = project
      @remote = remote
      @commit_id = commit_id
      @repo = Grit::Repo.init(File.join(@project.path, @commit_id))
    end

    def clone
      @repo.remote_add('origin', @remote)
      @repo.remote_fetch('origin')
    end

    def checkout
      @repo.git.checkout({:raise => true,
                           :base => false,
                           :chdir => @repo.working_dir}, @commit_id)
    end

    def run
      # TODO: log cmd errors
      return true if (@project.cmd.nil? || @project.cmd.empty?)
      process = Child.new(@project.cmd, :chdir => @repo.working_dir)
      process.status.success?
    end

    def deploy
      clone
      checkout
      run
    end
  end
end
