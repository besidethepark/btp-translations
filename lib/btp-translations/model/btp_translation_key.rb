module BtpTranslations
  class BtpTranslationKey < ActiveRecord::Base
    # ----------------------------------------------------------------------
    # Associations
    # ----------------------------------------------------------------------
    has_many :translations, class_name: 'BtpTranslationText', foreign_key: :btp_translation_key_id, dependent: :destroy

    # ----------------------------------------------------------------------
    # Attributes
    # ----------------------------------------------------------------------
    attr_accessible :key, :scope_separator, :translations, :translations_attributes
    accepts_nested_attributes_for :translations, allow_destroy: true

    # ----------------------------------------------------------------------
    # Validations
    # ----------------------------------------------------------------------
    validates :key, presence: true, uniqueness: true

    # ----------------------------------------------------------------------
    # Scopes
    # ----------------------------------------------------------------------
    scope :by_ids, ->(ids) { where('id IN (?)', ids) }

    # ----------------------------------------------------------------------
    # Callbacks
    # ----------------------------------------------------------------------
    before_save :normalize_newlines

    # ----------------------------------------------------------------------
    # Methods
    # ----------------------------------------------------------------------
    def self.translation(key, locale)
      nkey = newline_normalize(key)

      unless translation_key = find_by_key(nkey)
        Rails.logger.info("MISSING TRANSLATION KEY: #{nkey}")
        return nil
      end

      Rails.logger.info("DEPRECATED TRANSLATION KEY: #{nkey}") if translation_key.deprecated?
      return unless translation_text = translation_key.translations.find_by_locale(locale)
      translation_text.text
    end

    def self.available_locales
      @@available_locales ||= BtpTranslationText.count(group: :locale).keys.sort
    end

    private

    def self.newline_normalize(s)
      s.to_s.gsub("\r\n", "\n")
    end

    def normalize_newlines
      self.key = self.class.newline_normalize(key)
    end
  end
end