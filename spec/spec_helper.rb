require 'pacto'
require 'pacto/rspec'

Pacto.configure do |config|
  config.contracts_path = 'contracts'
end

pacto_mode = ENV['PACTO_MODE']
require "pacto_modes/#{pacto_mode}" if pacto_mode

stub_provider = ENV['STUB_WITH']
if stub_provider
  puts "Stubbing with: #{stub_provider}"
  require "stub_providers/#{stub_provider}"
else
  puts "Running live tests"
  WebMock.allow_net_connect!
end
