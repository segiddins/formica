# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'formica'
  spec.version       = File.read(File.expand_path('VERSION', __dir__)).strip
  spec.authors       = ['Samuel Giddins']
  spec.email         = ['segiddins@segiddins.me']

  spec.summary       = 'A gem for writing mergable, ' \
                       'lazily-evaluated configuration objects.'
  spec.homepage      = 'https://github.com/segiddins/formica'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '>= 1.16', '< 3'

  spec.required_ruby_version = '>= 2'
end
