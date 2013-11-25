# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'amqp_rails_worker/version'

Gem::Specification.new do |spec|
  spec.name          = 'amqp_rails_worker'
  spec.version       = AmqpRailsWorker::VERSION
  spec.authors       = ['Jana Dvorakova']
  spec.email         = ['jana4u@seznam.cz']
  spec.description   = %q{AMQP worker skeleton for Rails applications}
  spec.summary       = %q{AMQP worker skeleton for Rails applications}
  spec.homepage      = 'https://github.com/kraxnet/amqp_rails_worker'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
