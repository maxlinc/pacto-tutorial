# spec/support/fake_github.rb
require 'webmock/rspec'
require 'sinatra/base'

RSpec.configure do |config|
  config.before(:each) do
    stub_request(:any, /api.github.com/).to_rack(FakeGitHub)
  end
end

class FakeGitHub < Sinatra::Base
  get '/repos/:organization/:project/contributors' do
    json_response 200, 'contributors.json'
  end

  private

  def json_response(response_code, file_name)
    content_type :json
    status response_code
    fixture = File.join(File.dirname(__FILE__), '..', 'fixtures', "#{file_name}")
    File.read(fixture)
  end
end
