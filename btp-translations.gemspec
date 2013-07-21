# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'btp-translations/version'

Gem::Specification.new do |gem|
  gem.name          = 'btp-translations'
  gem.version       = Btp::Translations::VERSION
  gem.authors       = ['Beside the Park']
  gem.email         = ['contact@besidethepark.com']
  gem.description   = %q{Gem for gettext translations.}
  gem.summary       = %q{Gem for gettext translations.}
  gem.homepage      = ''

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_runtime_dependency 'rails', ['>= 3', '< 4']

  gem.add_dependency 'foreigner'
  gem.add_dependency 'activerecord-import', '>= 0.3.1'
  gem.add_dependency 'gettext_i18n_rails', '>= 0.9.4'
  gem.add_dependency 'rails-i18n', '>= 0.7.3'
  gem.add_dependency 'devise-i18n', '>= 0.8.3'
  gem.add_dependency 'will-paginate-i18n', '>= 0.1.13'
  gem.add_dependency 'activeadmin', '>= 0.6.0'

  gem.add_dependency 'appraisal'
  gem.add_dependency 'bump'
  gem.add_dependency 'gettext'
  gem.add_dependency 'haml'
  gem.add_dependency 'rails'
  gem.add_dependency 'rake'
  gem.add_dependency 'ruby_parser', '>= 3'
  gem.add_dependency 'rspec'
  gem.add_dependency 'slim'
  gem.add_dependency 'sqlite3'
end
