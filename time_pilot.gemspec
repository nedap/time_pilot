require_relative 'lib/time_pilot/version'

Gem::Specification.new do |s|
  s.name         = 'time_pilot'
  s.summary      = 'Configure enabled features for a specific set of users.'
  s.description  = ''
  s.version      = TimePilot::VERSION
  s.platform     = Gem::Platform::RUBY
  s.license      = 'MIT'

  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- {test}/*`.split("\n")
  s.require_path = 'lib'

  s.authors     = ['@mlangenberg', '@markoudev']
  s.email       = ['matthijs.langenberg@nedap.com', 'mark.oudeveldhuis@nedap.com']
  s.homepage    = 'https://github.com/nedap/time_pilot'

  s.add_dependency 'redis', '>= 4.8.0'
  s.add_dependency 'activesupport', '>= 3.0.0'
  s.add_development_dependency "minitest"
end
