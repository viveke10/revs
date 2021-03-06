set :rails_env, "production"
set :deployment_host, "revs-prod.stanford.edu"
set :bundle_without, [:deployment,:development,:test,:staging]

role :web, deployment_host, :primary => true
role :app, deployment_host
role :db,  deployment_host, :primary => true

after "deploy:finalize_update", "jetty:remove"