require File.expand_path("../spec_helper", File.dirname(__FILE__))

describe "project deploy" do
  before do
    @repo = Grit::Repo.init(File.join(Dir.mktmpdir))

    i = @repo.index
    i.add('foo', 'foo')
    @c1 = i.commit("add foo")
    i.add('bar', 'bar')
    @c2 = i.commit("add bar", [@c1])
    
    cmd = 'touch new.txt'
    options = {'branch' => 'master', 'cmd' => cmd}
    @project = GithubPostReceive::Project.new(Dir.mktmpdir, options)
    @project.deploy(@repo.path, @c1)
  end

  after do
    FileUtils.rm_rf(@repo.working_dir)
    FileUtils.rm_rf(@project.path)
  end

  it "should clone the repository" do
    Dir.exists?(File.join(@project.path, @c1, '.git')).should be_true
  end

  it "should run the specified command" do
    File.exists?(File.join(@project.path, @c1, 'new.txt')).should be_true
  end

  it "should setup a symlink" do
    current = File.join(@project.path, 'current')
    File.readlink(current).should == File.join(@project.path, @c1)
    Dir[File.join(current, "*")].map { |d| File.basename(d) }.sort.should ==
      ['foo', 'new.txt']
  end

  it "should replace the old symlink" do
    @project.deploy(@repo.path, @c2)
    current = File.join(@project.path, 'current')
    File.readlink(current).should == File.join(@project.path, @c2)
    Dir[File.join(current, "*")].map { |d| File.basename(d) }.sort.should ==
      ['bar', 'foo', 'new.txt']
    Dir.exists?(File.join(@project.path, @c1)).should_not be_true
  end

  it "should raise an exception if already deployed" do
    lambda { @project.deploy(@repo.path, @c1) }.
      should raise_error GithubPostReceive::AlreadyDeployed
    Dir.exists?(File.join(@project.path, @c1, '.git')).should be_true
    File.exists?(File.join(@project.path, @c1, 'new.txt')).should be_true
  end
end
