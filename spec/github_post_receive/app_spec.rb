require File.expand_path("../spec_helper", File.dirname(__FILE__))
require 'grit'

describe "application" do
  include Rack::Test::Methods

  def app
    GithubPostReceive::App
  end

  before do
    @repo = Grit::Repo.init(File.join(Dir.mktmpdir))

    i = @repo.index
    i.add('foo', 'foo')
    @c1 = i.commit("add foo")
    i.add('bar', 'bar')
    @c2 = i.commit("add bar", [@c1])

    @path = Dir.mktmpdir
    @hsh = {
      @path => {
        "name" => "baz",
        "branch" => "master",
        "cmd" => "touch new.txt"
      }
    }
    
    GithubPostReceive::App.load_hash(@hsh)

    @payload = {
      "repository" => {
        "name" => "baz",
        "url" => @repo.path
      },
      "ref" => "master",
      "after" => @c1
    }

    post '/notify', {:payload => @payload.to_json}
  end

  after do
    FileUtils.rm_rf(@repo.working_dir)
    FileUtils.rm_rf(@path)
  end

  it "should clone repository" do
    Dir.exists?(File.join(@path, @c1)).should be_true
  end
  
  it "should run the project cmd" do
    File.exists?(File.join(@path, @c1, 'new.txt')).should be_true
  end

  describe "when deployed multiple times" do
    before do
      @payload["after"] = @c2
    end
    
    describe "and cmd passes" do
      before do
        post '/notify', {:payload => @payload.to_json}
      end
      
      it "should update the current symlink" do
        File.readlink(File.join(@path, 'current')).should == File.join(@path, @c2)
      end

      it "should remove the old version" do
        Dir.exists?(File.join(@path, @c1)).should_not be_true
      end
    end

    describe "and cmd fails" do
      before do
        @hsh[@path]['cmd'] = "false"
        GithubPostReceive::App.load_hash(@hsh)
        post '/notify', {:payload => @payload.to_json}
      end
      
      it "should not change symlink" do
        File.readlink(File.join(@path, 'current')).should == File.join(@path, @c1)
      end

      it "should not remove old version" do
        Dir.exists?(File.join(@path, @c1)).should be_true
      end

      it "should remove the new version" do
        Dir.exists?(File.join(@path, @c2)).should_not be_true
      end
    end
  end
end
