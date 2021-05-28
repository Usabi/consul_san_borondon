# config valid only for current version of Capistrano
lock "~> 3.14.1"

def deploysecret(key)
  @deploy_secrets_yml ||= YAML.load_file("config/deploy-secrets.yml")[fetch(:stage).to_s]
  @deploy_secrets_yml.fetch(key.to_s, "undefined")
end

set :rails_env, fetch(:stage)
set :rvm1_ruby_version, "2.6.6"
set :rvm1_map_bins, -> { fetch(:rvm_map_bins).to_a.concat(%w[rake gem bundle ruby]).uniq }

set :application, "consul"
set :deploy_to, deploysecret(:deploy_to)
set :ssh_options, port: deploysecret(:ssh_port)

set :repo_url, "git@github.com:Usabi/consul_san_borondon.git"

set :revision, `git rev-parse --short #{fetch(:branch)}`.strip

set :log_level, :info
set :pty, true
set :use_sudo, false

set :linked_files, %w[config/database.yml config/secrets.yml]
set :linked_dirs, %w[.bundle log tmp public/system public/assets public/ckeditor_assets]

set :keep_releases, 5

set :local_user, ENV["USER"]

# set :puma_conf, "#{release_path}/config/puma/#{fetch(:rails_env)}.rb"

set :delayed_job_workers, 2
set :delayed_job_roles, :background

set :whenever_roles, -> { :app }

namespace :deploy do
 # after :updating, "rvm1:install:rvm"
 # after :updating, "rvm1:install:ruby"
 # after :updating, "install_bundler_gem"
  before "deploy:migrate", "remove_local_census_records_duplicates"

  after "deploy:migrate", "add_new_settings"
  after :publishing, "restart_tmp"

  before :publishing, "smtp_ssl_and_delay_jobs_secrets"
  # after  :publishing, "setup_puma"

  # after :published, "deploy:restart"
  # before "deploy:restart", "puma:smart_restart"
  before "deploy:restart", "delayed_job:restart"
  # before "deploy:restart", "puma:start"

  after :finished, "refresh_sitemap"

  desc "Deploys and runs the tasks needed to upgrade to a new release"
  task :upgrade do
    after "add_new_settings", "execute_release_tasks"
    invoke "deploy"
  end
end

task :install_ruby do
  on roles(:app) do
    within release_path do
      begin
        current_ruby = capture(:rvm, "current")
      rescue SSHKit::Command::Failed
        after "install_ruby", "rvm1:install:rvm"
        after "install_ruby", "rvm1:install:ruby"
      else
        if current_ruby.include?("not installed")
          after "install_ruby", "rvm1:install:rvm"
          after "install_ruby", "rvm1:install:ruby"
        else
          info "Ruby: Using #{current_ruby}"
        end
      end
    end
  end
end

task :refresh_sitemap do
  on roles(:app) do
    within release_path do
      with rails_env: fetch(:rails_env) do
        execute :rake, "sitemap:refresh:no_ping"
      end
    end
  end
end

task :add_new_settings do
  on roles(:db) do
    within release_path do
      with rails_env: fetch(:rails_env) do
        execute :rake, "settings:add_new_settings"
      end
    end
  end
end

task :execute_release_tasks do
  on roles(:app) do
    within release_path do
      with rails_env: fetch(:rails_env) do
        execute :rake, "consul:execute_release_tasks"
      end
    end
  end
end

desc "Create pid and socket folders needed by puma"
task :setup_puma do
  on roles(:app) do
    with rails_env: fetch(:rails_env) do
      execute "mkdir -p #{shared_path}/tmp/sockets; true"
      execute "mkdir -p #{shared_path}/tmp/pids; true"
    end
  end
end

desc "Restart application"
task :restart_tmp do
  on roles(:app) do
  execute "touch #{ File.join(current_path, "tmp", "restart.txt") }"
  end
end
