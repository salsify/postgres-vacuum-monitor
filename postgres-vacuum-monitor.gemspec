# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'postgres/vacuum/monitor/version'

Gem::Specification.new do |spec|
  spec.name          = 'postgres-vacuum-monitor'
  spec.version       = Postgres::Vacuum::Monitor::VERSION
  spec.authors       = ['Fernando Garces']
  spec.email         = ['fgarces@salsify.com']

  spec.summary       = 'Simple stats collector for postgres auto vacuumer.'
  spec.description   = 'Queries ActiveRecord DBs for info regarding auto vacuum processes and long running queries.'
  spec.homepage      = 'https://github.com/salsify/postgres-vacuum-monitor'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.6.0'

  spec.add_development_dependency 'appraisal'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'coveralls_reborn', '>= 0.18.0'
  spec.add_development_dependency 'database_cleaner'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.2'
  spec.add_development_dependency 'rspec_junit_formatter'
  spec.add_development_dependency 'salsify_rubocop'

  spec.add_dependency 'activerecord', '< 6.2.0'
  spec.add_dependency 'pg', '>= 0.18', '< 2.0'
end
