require 'rails/generators/active_record'

module DataQuality
  class DataQualityGenerator < ActiveRecord::Generators::Base

    desc "Create a migration to add data-quality-specific fields to your model. " +
         "The NAME argument is the name of your model"

    def self.source_root
      @source_root ||= File.expand_path('../templates', __FILE__)
    end

    def generate_migration
      migration_template 'migration.rb', 'db/migrate/create_quality_test_states.rb' rescue display $!.message
      migration_template "quality_score_migration.rb.erb", "db/migrate/#{migration_file_name}"
      puts "Please run rake db:migrate do apply the migrations."
    end

    protected

    def migration_name
      "add_quality_score_to_#{name.underscore.pluralize}"
    end

    def migration_file_name
      "#{migration_name}.rb"
    end

    def migration_class_name
      migration_name.camelize
    end
  end
end