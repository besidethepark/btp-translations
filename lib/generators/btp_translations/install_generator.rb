require 'fileutils'

module BtpTranslations
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../templates", __FILE__)

      desc "Generates migration for Btp Translations"

      def create_locale_directory
        p 'Creating directory btp_translations...'
        begin
          Dir::mkdir('locale')
          p 'Directory created'
        rescue
          p 'Directory btp_translations already exists!'
        end

        FileUtils.touch('locale/.gitkeep')
      end

      def create_migrations
        p 'Creating migrations...'

        Dir["#{self.class.source_root}/migrations/*.rb"].sort.each do |filepath|
          name = File.basename(filepath)
          template "migrations/#{name}", "db/migrate/#{Time.now.strftime('%Y%m%d%H%M%S')}_#{name}"
          sleep 1
        end

        p 'Migrations created'
      end
    end
  end
end