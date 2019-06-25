# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.name = 'model_transcribers'
  s.version = '0.0.1'
  s.date = '2019-06-16'
  s.summary = 'Transcribe '
  s.description = 'Transcribe content of attributes from a model to another.'
  s.authors = ['Joey Chung']
  s.email = 'hugtruem@gmail.com'
  s.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.require_paths = ['lib']
  s.homepage = 'https://github.com/hugtrueme/model_transcribers'
  s.license = 'MIT'

  s.add_runtime_dependency 'activerecord', '>= 5.1'
  s.add_runtime_dependency 'activesupport', '>= 5.1'
end
