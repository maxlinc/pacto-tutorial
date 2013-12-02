require 'pacto'
require 'pacto/rspec'

Pacto.configure do |config|
  config.contracts_path = 'contracts'
end

pacto_mode = ENV['PACTO_MODE']
require "pacto_modes/#{pacto_mode}" if pacto_mode

mock_provider = ENV['MOCK_WITH']
if mock_provider
  require "mock_providers/#{mock_provider}"
else
  # We're live!
  WebMock.allow_net_connect!
end
