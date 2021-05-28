set :branch, ENV["branch"] || :master
set :stage, :staging
set :rails_env, :staging

server deploysecret(:server), user: deploysecret(:user), roles: %w[web app db importer cron background]
