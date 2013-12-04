Pacto.validate!
hosts = Dir["#{Pacto.configuration.contracts_path}/*"].each do |host|
  host = File.basename host
  Pacto.load_all host, "https://#{host}", :default
end
Pacto.use :default
