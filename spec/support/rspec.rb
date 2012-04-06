RSpec.configure do |config|
  config.mock_with :rspec

  config.after(:each) do
  end

  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end
