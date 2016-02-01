$LOAD_PATH.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'akamai_rspec'
  s.version     = '0.3.0'
  s.authors     = ['Bianca Gibson']
  s.email       = 'bianca.gibson@rea-group.com'
  s.files       = Dir['lib/*']
  s.summary     = 'Test your akamai configuration with rspec'
  s.description = 'Test your akamai configuration with rspec'
  s.add_runtime_dependency('rest-client', '~> 1.8')
  s.add_runtime_dependency('json', '~> 1.8')
  s.add_runtime_dependency('rspec', '~> 3.2')
  s.files = `git ls-files lib`.split($RS)
  s.require_paths = ['lib']
  s.licenses = 'MIT'
  s.homepage = 'https://github.com/realestate-com-au/akamai-rspec'
end
