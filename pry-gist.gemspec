require './lib/pry-gist/version'

Gem::Specification.new do |s|
  s.name        = 'pry-gist'
  s.version     = PryGist::VERSION
  s.date        = Time.now.strftime('%Y-%m-%d')
  s.summary     = 'Upload code, docs, history to https://gist.github.com/'
  s.authors     = ['Kyrylo Silin']
  s.email       = %w[silin@kyrylo.org]
  s.homepage    = 'http://pryrepl.org'
  s.license     = 'MIT'

  s.require_path = 'lib'
  s.files        = ['lib/pry-gist.rb', *Dir.glob('lib/**/*')]
  s.test_files   = Dir.glob('spec/**/*')

  s.required_ruby_version = '>= 1.9'

  s.add_dependency 'pry', '~> 0.12'
  s.add_dependency 'gist', '~> 5.0'

  s.add_development_dependency 'rspec', '~> 3.8'
  s.add_development_dependency 'rake', '~> 10.0'
end
