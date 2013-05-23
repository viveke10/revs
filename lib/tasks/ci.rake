require 'jettywrapper' unless Rails.env.production? 
require 'rest_client'

desc "Run continuous integration suite"
task :ci do
  unless Rails.env.test?  
    system("rake ci RAILS_ENV=test")
  else
    system("rake db:migrate RAILS_ENV=test")  
    Jettywrapper.wrap(Jettywrapper.load_config) do
      Rake::Task["revs:refresh_fixtures"].invoke
      Rake::Task["db:fixtures:load"].invoke
      Rake::Task["db:seed"].invoke      
      Rake::Task["rspec"].invoke
    end
  end
end

desc "Assuming jetty is already running - then migrate, reload all fixtures and run rspec"
task :local_ci do  
  Rails.env='test'
  ENV['RAILS_ENV']='test'
  Rake::Task["revs:refresh_fixtures"].invoke
  Rake::Task["db:fixtures:load"].invoke
  Rake::Task["db:seed"].invoke
  Rake::Task["rspec"].invoke
end

namespace :revs do

  desc "Copy configuration files"
  task :config do
    cp("#{Rails.root}/config/database.yml.example", "#{Rails.root}/config/database.yml") unless File.exists?("#{Rails.root}/config/database.yml")
    cp("#{Rails.root}/config/solr.yml.example", "#{Rails.root}/config/solr.yml") unless File.exists?("#{Rails.root}/config/solr.yml")
  end  
  
  desc "Delete and index all fixtures in solr"
  task :refresh_fixtures do
    unless Blacklight.solr.uri.port == 8080
      Rake::Task["revs:delete_records_in_solr"].invoke
      Rake::Task["revs:index_fixtures"].invoke
    else
      puts "Refusing to refresh fixtures since you are connecting on port 8080.  You know, for safety."
    end
  end
  
  desc "Index all fixutres into solr"
  task :index_fixtures do
    add_docs = []
    Dir.glob("#{Rails.root}/spec/fixtures/*.xml") do |file|
      add_docs << File.read(file)
    end
    puts "Adding #{add_docs.count} documents to #{Blacklight.solr.options[:url]}"
    RestClient.post "#{Blacklight.solr.options[:url]}/update?commit=true", "<update><add>#{add_docs.join(" ")}</add></update>", :content_type => "text/xml"
  end
  
  desc "Delete all records in solr"
  task :delete_records_in_solr do
   unless Rails.env.production? || Blacklight.solr.uri.port == 8080
      puts "Deleting all solr documents from #{Blacklight.solr.options[:url]}"
      RestClient.post "#{Blacklight.solr.options[:url]}/update?commit=true", "<delete><query>*:*</query></delete>" , :content_type => "text/xml"
    else
      puts "Refusing to delete since we're running under the #{Rails.env} environment or connecting on port 8080. You know, for safety."
    end
  end
end