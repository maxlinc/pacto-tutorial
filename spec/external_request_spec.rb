require 'spec_helper'

describe 'External request', :vcr => true do
  it 'queries FactoryGirl contributors on Github' do
    uri = URI('https://api.github.com/repos/thoughtbot/factory_girl/contributors')

    response = Net::HTTP.get(uri)

    expect(response).to be_an_instance_of(String)
    expect(Pacto).to have_validated(:get, 'https://api.github.com/repos/thoughtbot/factory_girl/contributors')
        .against_contract /contributors.json/
    expect(Pacto).to_not have_failed_validations
    expect(Pacto).to_not have_unmatched_requests
  end
end
