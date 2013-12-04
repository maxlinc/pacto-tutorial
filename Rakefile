require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

namespace :test do
  desc "Run the tests against the live service and then against each stub provider"
  task :all => [:live, :webmock, :vcr, :sinatra, :pacto]

  desc "Run the tests against the real services"
  task :live do
    ENV['STUB_WITH'] = nil
    Rake::Task["spec"].execute
  end

  ['webmock', 'vcr', 'sinatra', 'pacto'].each do |stub_with|
    desc "Run tests while stubbing with #{stub_with}"
    task stub_with do
      ENV['STUB_WITH'] = stub_with
      Rake::Task["spec"].execute
    end
  end
end

