$LOAD_PATH.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'akamai_rspec'
  s.version     = '0.1.1'
  s.authors     = ['Bianca Gibson']
  s.email       = 'bianca.gibson@rea-group.com'
  s.files       = Dir['lib/*']
  s.summary     = 'Matchers and other useful bits and pieces for testing your akamai config'
  s.add_runtime_dependency('rest-client', '~> 1.7')
  s.add_runtime_dependency('json', '~> 1.8')
  s.add_runtime_dependency('rspec', '~> 3.2')
  s.files = `git ls-files lib`.split($RS)
  s.require_paths = ['lib']
end
