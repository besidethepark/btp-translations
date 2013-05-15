module BtpTranslations
  class BtpTranslationText < ActiveRecord::Base
    # ----------------------------------------------------------------------
    # Associations
    # ----------------------------------------------------------------------
    belongs_to :translation_key, class_name: 'BtpTranslationKey', foreign_key: :btp_translation_key_id

    # ----------------------------------------------------------------------
    # Attributes
    # ----------------------------------------------------------------------
    attr_accessible :text, :btp_translation_key_id, :locale

    # ----------------------------------------------------------------------
    # Validations
    # ----------------------------------------------------------------------
    validates :btp_translation_key_id, presence: true
    validates :btp_translation_key_id, uniqueness: { scope: :locale }
    validates :locale, presence: true
    validates :text, presence: true

    # ----------------------------------------------------------------------
    # Scopes
    # ----------------------------------------------------------------------
    scope :with_translation_key, includes(:translation_key)
    scope :by_locale, ->(locale) { where('locale = ?', locale) }
  end
end