require 'bundler/rubygems_ext'
$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'hailstorm/version'

Gem::Specification.new do |gem|
  gem.name        = 'hailstorm'
  gem.version     = Hailstorm::VERSION
  gem.platform    = Gem::Platform::JAVA
  gem.authors     = ['3Pillar Global']
  gem.email       = %w[labs@3pillarglobal.com]
  gem.homepage    = 'http://labs.3pillarglobal.com/hailstorm'
  gem.summary     = 'A cloud-aware library and embedded application for distributed load testing using JMeter and
optional server monitoring'
  gem.description = 'Hailstorm uses JMeter to generate load on the system under test. You create your JMeter test
plans/scripts using JMeter GUI interface and place the plans and the data files in a specific application directory.
Hailstorm provides a console(shell) interface where you can configure your test environment, start tests, stop tests
and generate reports. Behind the scenes, Hailstorm uses Amazon EC2 to create load agents. Each load agent is
pre-installed with JMeter. The application executes your test plans in non-GUI mode using these load agents.

Hailstorm can monitor server side resources,though at the moment, the server side monitoring is limited to UNIX hosts.

Hailstorm works in an offline mode by default, which means you can exit the application and leave your tests running.'

  gem.rubyforge_project = 'hailstorm'

  gem.license = 'MIT'

  included_globs = %w[bin features lib resources spec templates].collect { |e| ["#{e}/**/*", "#{e}/**/.*"] }.flatten
  included_files = %w[.rspec .rubocop.yml .simplecov Gemfile hailstorm.gemspec Rakefile README.md Vagrantfile]
  excluded_files = %w[Gemfile.lock .gitignore features/data/all_purpose.pem features/data/data-center-machines.yml
                      features/data/keys.yml features/data/site_server.txt lib/hailstorm/java/.project]
  gem.files         = Dir.glob(included_globs).select { |f| File.file?(f) } + included_files - excluded_files
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/\b})
  gem.executables   = gem.files.grep(%r{^bin/\b}).map { |f| File.basename(f) }
  gem.require_paths = %w[lib]

  # dependencies
  gem.add_dependency('actionpack', ['= 4.2.8'])
  gem.add_dependency('activerecord', ['= 4.2.8'])
  gem.add_dependency('activerecord-jdbc-adapter', ['~> 1.3'])
  gem.add_dependency('aws-sdk', '= 1.57.0')
  gem.add_dependency('bouncy-castle-java', '= 1.5.0146.1')
  gem.add_dependency('haikunator', '= 1.1.0')
  gem.add_dependency('httparty', '= 0.13.1')
  gem.add_dependency('i18n', ['~> 0.7'])
  gem.add_dependency('jruby-openssl', '~> 0.9')
  gem.add_dependency('net-sftp', '= 2.1.2')
  gem.add_dependency('net-ssh', '~> 4.2')
  gem.add_dependency('nokogiri', '~> 1.6.3.1')
  gem.add_dependency('rubyzip', '= 1.2.1')
  gem.add_dependency('terminal-table', '= 1.4.5')

  gem.add_development_dependency('activerecord-jdbcmysql-adapter', ['~> 1.3'])
  gem.add_development_dependency('activerecord-jdbcsqlite3-adapter', ['~> 1.3'])
  gem.add_development_dependency('cucumber', '~> 2.99')
  gem.add_development_dependency('rspec', '~> 2.13.0')
  gem.add_development_dependency('rubocop')
  gem.add_development_dependency('ruby-debug')
  gem.add_development_dependency('simplecov')
end
