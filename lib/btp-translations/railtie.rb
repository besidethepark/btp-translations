module BtpTranslations
  class Railtie < Rails::Railtie
    initializer 'railtie.fast_gettext' do
      require 'fast_gettext/translation_repository/db'

      # db access is cached <-> only first lookup hits the db
      # don't load and include default models - we have our own custom models
      ::FastGettext::TranslationRepository::Db.seperator = '--->'
      ::FastGettext.add_text_domain('Btp-Transpations', type: :db, model: BtpTranslations::BtpTranslationKey)
      ::FastGettext.default_text_domain = 'Btp-Transpations'

      ::GettextI18nRails.translations_are_html_safe = true
      ::I18n.locale = I18n.default_locale
      ::I18n.default_separator = '|'
    end
    rake_tasks { load 'btp-translations/tasks/btp-translations.rake' }
  end
end