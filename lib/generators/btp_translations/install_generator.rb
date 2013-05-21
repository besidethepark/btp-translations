require 'fileutils'

module BtpTranslations
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../templates", __FILE__)

      desc "Generates directories, files and migrations for Btp Translations"

      def create_locale_directory
        p 'Creating directory btp_translations...'
        begin
          Dir::mkdir('locale')
          FileUtils.touch('locale/.gitkeep')
          p 'Directory created.'
        rescue
          p 'Directory btp_translations already exists!'
        end
      end

      def create_initializers
        p 'Creating initializers...'

        Dir["#{self.class.source_root}/initializers/*.rb"].each do |filepath|
          name = File.basename(filepath)
          begin
            template "initializers/#{name}", "config/initializers/#{name}"
            p "config/initializers/#{name} created"
          rescue
            p "config/initializers/#{name} already exists"
          end
          sleep 1
        end
      end

      def create_migrations
        p 'Creating migration...'
        current_migrations = Dir["db/migrate/*"].collect{ |file| file.to_s }

        Dir["#{self.class.source_root}/migrations/*.rb"].sort.each do |filepath|
          name = File.basename(filepath)
          timestamp = Time.now.strftime('%Y%m%d%H%M%S')
          begin
            raise 'Migration already exists' if current_migrations.any? { |migration| migration.match(/\bdb\/migrate\/\d{14}_#{name}\b/) }

            template "migrations/#{name}", "db/migrate/#{timestamp}_#{name}"
            p "db/migrate/#{timestamp}_#{name} created"
          rescue
            p "db/migrate/#{timestamp}_#{name} already exists"
          end
          sleep 1
        end
      end
    end
  end
end