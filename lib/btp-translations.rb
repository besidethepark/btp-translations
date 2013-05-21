require "btp-translations/version"
require 'btp-translations/railtie' if defined?(Rails)

require 'foreigner'
require 'activerecord-import'
require 'gettext_i18n_rails'
require 'rails-i18n'
require 'devise-i18n'
require 'will-paginate-i18n'

module BtpTranslations
  require 'btp-translations/model/btp_translation_key'
  require 'btp-translations/model/btp_translation_text'
end
