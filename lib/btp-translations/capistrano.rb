require 'btp-translations/capistrano/recipes'

Capistrano::Configuration.instance(:must_exist).load do
  after 'deploy:create_symlink', 'btp_translations:discover_translations'
  after 'deploy:create_symlink', 'btp_translations:copy_translations'
end