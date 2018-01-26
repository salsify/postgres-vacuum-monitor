
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'postgres/vacuum/monitor/version'

Gem::Specification.new do |spec|
  spec.name          = 'postgres-vacuum-monitor'
  spec.version       = Postgres::Vacuum::Monitor::VERSION
  spec.authors       = ['Fernando Garces']
  spec.email         = ['fergarcesf@gmail.com']

  spec.summary       = 'Simple stats collector for postgres auto vacuumer.'
  spec.description   = 'Queries the Active Record DB for information regarding the auto vacuum process and long running queries'
  spec.homepage      = 'https://github.com/salsify/postgres-vacuum-monitor'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'appraisal'
  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'database_cleaner'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.2'
  spec.add_development_dependency 'salsify_rubocop'

  spec.add_dependency 'activejob'
  spec.add_dependency 'activerecord'
  spec.add_dependency 'pg', '~> 0.18'
end
