require 'spec_helper'

describe 'External request', :vcr => true do
  it 'queries FactoryGirl contributors on Github' do
    uri = URI('https://api.github.com/repos/thoughtbot/factory_girl/contributors')
    response = do_request(uri)

    expect(response).to be_an_instance_of(Net::HTTPOK)
  end

  def do_request(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    request = Net::HTTP::Get.new(uri.request_uri)
    http.request(request)
  end
end
