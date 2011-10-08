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
      init_cache
      init_repo
    end

    def init_cache
      cache_path = File.join(@project.path, 'cache.git')
      @cache = Grit::Repo.init_bare(cache_path)
    end

    def init_repo
      path = File.join(@project.path, @commit_id)
      raise AlreadyDeployed.new(path) if File.exists? path
      @repo = Grit::Repo.init(path)
    end

    def git_options
      {:raise => true, :timeout => @project.timeout}
    end

    def list_mirrors(repo)
      Dir.glob(File.join(repo.path, 'refs/heads/*')).map do |path|
        File.basename(path)
      end
    end

    def cache
      if list_mirrors(@cache).empty?
        App.logger.debug "Adding #{@remote} as 'origin'"
        @cache.git.remote(git_options, 'add', '--mirror', 'origin', @remote)
      end
      App.logger.debug "Updating from #{@remote}"
      @cache.git.remote(git_options, 'update')
    end

    def clone
      App.logger.debug "Adding #{@cache.path} as 'origin'"
      @repo.git.remote(git_options, 'add', 'origin', @cache.path)
      App.logger.debug "Fetching #{@cache.path}"
      @repo.git.fetch(git_options, 'origin')
    end

    def checkout
      options = git_options.merge({:base => false, :chdir => @repo.working_dir})
      @repo.git.checkout(options, @commit_id)
    end

    def run
      return true if (@project.cmd.nil? || @project.cmd.empty?)
      process = Child.new(@project.cmd, :chdir => @repo.working_dir)
      raise process.err unless process.status.success?
      return true
    end

    def deploy
      cache
      clone
      checkout
      run
    rescue => e
      App.logger.error "Deploy failed [#{@project.name}][#{@project.path}][#{@commit_id}]: #{e.inspect}"
      return false
    end
  end
end
