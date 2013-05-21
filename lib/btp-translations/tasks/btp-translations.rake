namespace :btp_translations do
  def load_gettext
    require 'gettext'
    require 'gettext/utils'
  end

  desc 'Show files to translate'
  task files: :environment do
    files_to_translate.each { |path| p path }
  end

  desc 'Update pot/po files.'
  task discover: :environment do
    FileUtils.rm_rf(File.join(locale_path, '*'))
    load_gettext
    store_model_attributes

    $LOAD_PATH << File.join(File.dirname(__FILE__),'..','..','lib') # needed when installed as plugin

    require 'gettext_i18n_rails/haml_parser'
    require 'gettext_i18n_rails/slim_parser'

    msgmerge = Rails.application.config.gettext_i18n_rails.msgmerge

    GetText.update_pofiles_org(
        text_domain,
        files_to_translate,
        'version 0.0.1',
        po_root: locale_path,
        msgmerge: msgmerge
    )

    store_keys_in_database
  end

  def store_model_attributes
    require 'gettext_i18n_rails/model_attributes_finder'

    storage_file = "#{locale_path}/model_attributes.rb"
    puts "writing model translations to: #{storage_file}"

    ignore_tables  = [/^sitemap_/, /_versions$/, /^schema_migrations$/, /^sessions$/, /^delayed_jobs$/]
    ignore_columns = [/_id$/, /^id$/, /^type$/, /^created_at$/, /^updated_at$/]

    File.open(storage_file, 'w') do |f|
      f.puts '#DO NOT MODIFY! AUTOMATICALLY GENERATED FILE!'
      GettextI18nRails::ModelAttributesFinder.new.models.each do |model|
        unless model.abstract_class || ignore_tables.map { |ignored_table| model.table_name.match(ignored_table) }.compact.present?
          f.puts("_('#{model.humanize_class_name}')")

          attributes = (model.new.attributes.keys + model.accessible_attributes.select { |attr| attr.present? }).uniq.sort
          attributes.each do |attribute|
            unless ignore_columns.map { |ignored_column| attribute.match(ignored_column) }.compact.present?
              f.puts("_('#{model.gettext_translation_for_attribute_name(attribute)}')")
              f.puts("_('#{model.gettext_translation_for_attribute_name(attribute)} tip')")
            end
          end
        end
      end

      f.puts '#DO NOT MODIFY! AUTOMATICALLY GENERATED FILE!'
    end
  end

  def locale_path
    path = FastGettext.translation_repositories[text_domain].instance_variable_get(:@options)[:path] rescue nil
    path || File.join(Rails.root, 'locale')
  end

  def text_domain
    # if your textdomain is not 'app': require the environment before calling e.g. gettext:find OR add TEXTDOMAIN=my_domain
    ENV['TEXTDOMAIN'] || (FastGettext.text_domain rescue nil) || "app"
  end

  # do not rename, gettext_i18n_rails_js overwrites this to inject coffee + js
  def files_to_translate
    Dir.glob("{app,lib,config,#{locale_path}}/**/*.{rb,erb,haml,slim}")
  end

  def store_keys_in_database
    all_translations = {}
    locales.each { |locale| all_translations[locale] = {} }

    # Get translations from a .pot file
    require 'fast_gettext/mo_file'
    require 'fast_gettext/vendor/poparser'

    mo_file = FastGettext::GetText::MOFile.new
    parser = FastGettext::GetText::PoParser.new

    pot_content = File.read("#{locale_path}/#{text_domain}.pot").gsub('msgstr ""', 'msgstr "__EMPTY_TRANSLATION__"')

    parser.parse(pot_content, mo_file)
    mo_file.delete('')

    mo_file.keys.each { |key| mo_file[key] = key.split('|').last if mo_file[key].eql?('__EMPTY_TRANSLATION__') }

    all_translations['en'] = mo_file.to_hash

    translations_with_dots = {}

    # Get standard rails translations
    locales.each do |locale|
      yaml = File.read(File.join(Gem.loaded_specs['rails-i18n'].full_gem_path, 'rails', 'locale', "#{locale}.yml"))
      yaml_hash = YAML.load(yaml)
      rails_translations = hash_dst(yaml_hash[locale], '.')

      all_translations[locale].merge!(rails_translations)
      rails_translations.keys.each { |key| translations_with_dots[key] = true }
    end

    # Get standard devise translations
    locales.each do |locale|
      yaml = File.read(File.join(Gem.loaded_specs['devise-i18n'].full_gem_path, 'locales', "#{locale}.yml"))
      yaml_hash = YAML.load(yaml)
      devise_translations = hash_dst(yaml_hash[locale], '.')

      all_translations[locale].merge!(devise_translations)
      devise_translations.keys.each { |key| translations_with_dots[key] = true }
    end

    # Get standard will paginate translations
    locales.each do |locale|
      yaml = File.read(File.join(Gem.loaded_specs['will-paginate-i18n'].full_gem_path, 'locales', "#{locale}.yml"))
      yaml_hash = YAML.load(yaml)
      will_paginate_translations = hash_dst(yaml_hash[locale], '.')

      all_translations[locale].merge!(will_paginate_translations)
      will_paginate_translations.keys.each { |key| translations_with_dots[key] = true }
    end

    # Get keys translations from a database
    # Take all keys and add them into a hash
    current_keys = {}
    BtpTranslations::BtpTranslationKey.all.each { |translation_key| current_keys[translation_key.key] = translation_key }

    undeprecated_keys = {}
    new_keys  = []

    locales.collect { |locale| all_translations[locale].keys }.flatten.uniq.each do |key|
      if current_keys[key].present?
        undeprecated_keys[key] = true
      else
        new_keys << BtpTranslations::BtpTranslationKey.new(key: key, scope_separator: translations_with_dots[key] ? '.' : '|')
      end
    end

    deprecated_key_ids   = []
    undeprecated_key_ids = []

    current_keys.each_pair do |key_name, key|
      if key.deprecated? && undeprecated_keys[key_name]
        undeprecated_key_ids << key.id
      elsif !key.deprecated? && !undeprecated_keys[key_name]
        deprecated_key_ids << key.id
      end
    end

    BtpTranslations::BtpTranslationKey.by_ids(deprecated_key_ids).update_all(deprecated: true, updated_at: Time.now)
    BtpTranslations::BtpTranslationKey.by_ids(undeprecated_key_ids).update_all(deprecated: false, updated_at: Time.now)

    BtpTranslations::BtpTranslationKey.import(new_keys) if new_keys.present?

    translations_to_create = []

    locales.each do |locale|
      current_translations = {}

      BtpTranslations::BtpTranslationText.with_translation_key.by_locale(locale).all.each do |translation_text|
        current_translations[translation_text.translation_key] = translation_text.text
      end

      all_translations[locale].each_pair do |key, value|
        if current_translations[key].blank?
          translations_to_create << BtpTranslations::BtpTranslationText.new(btp_translation_key_id: BtpTranslations::BtpTranslationKey.find_by_key(key).id, locale: locale, text: value)
        elsif current_translations[key].text.blank?
          current_translations[key].update_attribute(:text, value)
        end
      end
    end

    BtpTranslations::BtpTranslationText.import(translations_to_create)
  end

  def hash_dst(root, separator = '|', keys = [])
    hash = {}

    root.each_pair do |key, value|
      new_level_keys = keys + [key]

      if value.is_a?(Hash)
        hash.merge!(hash_dst(value, separator, new_level_keys))
      elsif value.is_a?(String)
        hash[new_level_keys.join(separator)] = value
      end
    end

    hash
  end

  def locales
    BTP_TRANSLATIONS_LOCALES
  end

  desc 'Update pot/po files.'
  task clear: :environment do
    BtpTranslations::BtpTranslationKey.delete_all
  end
end