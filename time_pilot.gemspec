Gem::Specification.new do |s|
  s.name         = 'time_pilot'
  s.summary      = 'Configure enabled features for a specific set of users.'
  s.description  = ''
  s.version      = '0.0.1'
  s.platform     = Gem::Platform::RUBY
  s.license      = 'MIT'

  s.files        = ['lib/time_pilot.rb']
  s.require_path = '.'

  s.authors     = ['@mlangenberg', '@markoudev']
  s.email       = ['matthijs.langenberg@nedap.com', 'mark.oudeveldhuis@nedap.com']
  s.homepage    = ''

  s.add_development_dependency "minitest"
end
