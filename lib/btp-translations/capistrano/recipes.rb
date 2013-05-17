Capistrano::Configuration.instance(:must_exist).load do
  namespace :btp_translations do

    desc "Discover translations on the source instance"
    task :discover_translations do
      if stage.to_s == btp_translations_source_stage.to_s
        run "cd #{current_path}; bundle exec rake btp_translations:discover RAILS_ENV=#{rails_env}"
      end
    end

    desc "Copy translations from the source instance"
    task :copy_translations do
      source_stage = btp_translations_source_stage

      if source_stage.to_s != btp_translations_source_stage.to_s
        ssh_user = ssh_address = ssh_port = ssh_path = ssh_env = nil

        files = [File.join('config', 'deploy', "#{source_stage}.rb"), File.join('config', 'deploy.rb')]

        files.each do |file|
          File.readlines(file).each do |line|
            if line.include?('role') && line.include?('app') && ssh_address.nil?
              ssh_address = line[/\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b/]
              ssh_port    = line[/\b:\d{1,6}\b/].gsub(':', '') || 22
            elsif line.include?('set') && line.include?('user') && ssh_user.nil?
              ssh_user = line.split(',').last.gsub('"', '').gsub('\'', '').strip
            elsif line.include?('set') && line.include?('deploy_to') && ssh_path.nil?
              ssh_path = line.split(',').last.gsub('"', '').gsub('\'', '').strip
            elsif line.include?('set') && line.include?('rails_env') && ssh_env.nil?
              ssh_env = line.split(',').last.gsub('"', '').gsub('\'', '').strip
            end
          end
        end

        run "ssh #{ssh_user}@#{ssh_address} -p #{ssh_port} &&
          $(ruby -e \"require 'yaml'; db_config = YAML.load_file('#{ssh_path}/shared/config/database.yml')['#{ssh_env}']; puts 'mysqldump --user=' + db_config['username'] + ' --password=' + db_config['password'] + ' ' + db_config['database'] + ' btp_translation_keys btp_translation_texts'\") > #{ssh_path}/current/tmp/btp_translations.sql
          && exit"

        run "scp -P #{ssh_port} #{ssh_user}@#{ssh_address}:#{ssh_path}/current/tmp/btp_translations.sql ./"

        run "$(ruby -e \"require 'yaml'; db_config = YAML.load_file('#{deploy_to}/shared/config/database.yml')['#{rails_env}']; puts 'mysql --user=' + db_config['username'] + ' --password=' + db_config['password'] + ' ' + db_config['database']\") < ./btp_translations.sql"
      end
    end
  end
end