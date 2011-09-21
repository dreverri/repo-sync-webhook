module GithubPostReceive  
  class App < Sinatra::Application
    def self.load_config(fname)
      hsh = YAML.load(ERB.new(File.read(File.expand_path(fname))).result)
      load_hash(hsh)
    end

    def self.load_hash(hsh)
      set :projects, hsh.map { |path, config| Project.new(path, config) }
    end

    configure do
      use Rack::Logger
      enable :lock
    end

    get '/' do
      "Nothing to see here"
    end

    post '/notify' do
      process_request(params, settings.projects)
      "Thank you"
    end

    helpers do  
      def process_request(params, projects)
        payload = Payload.from_params(params)
        projects.each do |project|
          if project.match?(payload)
            project.deploy(payload.url, payload.commit_id)
          end
        end
      end

      def url(payload, project)
        project['remote'] || payload['repository']['url']
      end

      def logger
        env['rack.logger'] 
      end
    end
  end
end
