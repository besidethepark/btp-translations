class CreateBtpTranslations < ActiveRecord::Migration
  def up
    create_table :btp_translation_keys do |t|
      t.string :key, unique: true, null: false
      t.string :category
      t.string :scope_separator, limit: 4, default: '|', null: false
      t.boolean :deprecated, default: false, null: false
      t.boolean :disabled, default: false, null: false
      t.timestamps
    end

    add_index :btp_translation_keys, :key

    create_table :btp_translation_texts do |t|
      t.text :text
      t.string :locale, limit: 5, null: false, default: 'en'
      t.references :btp_translation_key, null: false
      t.timestamps
    end

    add_foreign_key :btp_translation_texts, :btp_translation_keys, dependent: :delete
  end

  def down
    drop_table :btp_translation_texts
    drop_table :btp_translation_keys
  end
end
