require 'net/ssh/kerberos'
require 'bundler/setup'
require 'bundler/capistrano'
require 'dlss/capistrano'
require 'pathname'
require 'squash/rails/capistrano2'
require 'whenever/capistrano'

set :stages, %W(staging development production)
set :bundle_flags, "--quiet"
set :repository, "https://github.com/sul-dlss/revs"
set :whenever_command, "bundle exec whenever"
set :deploy_via, :remote_cache
set :whenever_command, "bundle exec whenever"
set :whenever_environment, defer { stage }

require 'capistrano/ext/multistage'

set :shared_children, %w(
  log 
  config/database.yml
  config/solr.yml
  public/uploads
)

set :user, "lyberadmin" 
set :runner, "lyberadmin"
set :ssh_options, {
  :auth_methods  => %w(gssapi-with-mic publickey hostbased),
  :forward_agent => true
}

set :destination, "/home/lyberadmin"
set :application, "revs-lib"

set :scm, :git
set :copy_cache, true
set :copy_exclude, [".git"]
set :use_sudo, false
set :keep_releases, 3

set :deploy_to, "#{destination}/#{application}"

set :branch do
  last_tag = `git describe --abbrev=0 --tags`.strip
  default_tag = 'master'
  
  tag = Capistrano::CLI.ui.ask "Tag to deploy (make sure to push the tag first): [default: #{default_tag}, last tag: #{last_tag}] "
  tag = default_tag if tag.empty?
  tag
end

namespace :jetty do
  task :start do 
    run "cd #{deploy_to}/current && rake jetty:start RAILS_ENV=#{rails_env}"
  end
  task :stop do
    run "if [ -d #{deploy_to}/current ]; then cd #{deploy_to}/current && rake jetty:stop RAILS_ENV=#{rails_env}; fi"
  end
  task :remove do
    run "rm -fr #{release_path}/jetty"
  end  
  task :symlink do
    run "rm -fr #{release_path}/jetty"
    run "ln -s #{shared_path}/jetty #{release_path}/jetty"
  end
end

namespace :fixtures do
  task :ingest do
    run "cd #{deploy_to}/current && rake revs:index_fixtures RAILS_ENV=#{rails_env}"
  end
  task :refresh do
    run "cd #{deploy_to}/current && rake revs:refresh_fixtures RAILS_ENV=#{rails_env}"
  end
end

namespace :db do
  task :migrate do
    run "cd #{deploy_to}/current && rake db:migrate RAILS_ENV=#{rails_env}"
  end
  task :loadfixtures do
    run "cd #{deploy_to}/current && rake db:fixtures:load RAILS_ENV=#{rails_env}"
  end
  task :loadseeds do
    run "cd #{deploy_to}/current && rake db:seed RAILS_ENV=#{rails_env}"
  end  
  task :symlink_sqlite do
    run "ln -s #{shared_path}/#{rails_env}.sqlite3 #{release_path}/db/#{rails_env}.sqlite3"
  end  
end

namespace :deploy do
  task :symlink_editstore do
    run "ln -s /home/lyberadmin/editstore-updater/current/public #{release_path}/public/editstore"
  end  
  task :dev_options_set do
    run "cd #{deploy_to}/current && rake revs:dev_options_set RAILS_ENV=#{rails_env}"
  end
  task :symlink_uploads do
    run "rm -fr #{release_path}/public/uploads && ln -s #{shared_path}/uploads #{release_path}/public/uploads"
  end
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

before 'deploy:assets:precompile', 'squash:write_revision'
after "deploy:create_symlink", "deploy:migrate"
after "deploy:update", "deploy:cleanup" 
after "deploy:update", "deploy:dev_options_set"
after "deploy:finalize_update", "deploy:symlink_editstore"
after "deploy:finalize_update", "deploy:symlink_uploads"
