$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
require 'rubygems'
require 'sqlite3'
require 'active_record'

require 'simplecov'
SimpleCov.start

require 'data_quality'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

ActiveRecord::Schema.define(:version => 1) do

  create_table "quality_test_states" do |t|
    t.string :identifier
    t.boolean :not_applicable
    t.integer :testable_id
    t.string :testable_type
  end

  create_table "companies", :force => true do |t|
    t.string   :name
    t.string   :start_of_operations
    t.string   :end_of_operations
    t.integer  :quality_score,                    :default => 0
    t.integer  :failed_tests,                     :default => 0
  end

  create_table "people", :force => true do |t|
    t.string   :name
    t.integer  :company_id
    t.date     :employed_since
    t.integer  :quality_score,                    :default => 0
    t.integer  :failed_tests,                     :default => 0
  end
end




class Company < ActiveRecord::Base
  has_many :people

  has_quality_tests do
    quality_test '01', :method_name => :not_empty, :attr => :name
    quality_test '02',  :method_name => :not_empty, :attr => :start_of_operations
    quality_test '03', :method_name => :not_empty, :attr => :end_of_operations, :if => lambda {|company| !company.start_of_operations.blank?}
    quality_test '04', :method_name => :each_not_empty, :attr => :employed_since, :function => :people
    quality_test '05', :description => "Company.end_of_operations is later than Company.start_of_operations", :if => lambda {|company| !company.start_of_operations.blank? and !company.end_of_operations.blank?} do |company|
      company.start_of_operations < company.end_of_operations
    end
    quality_test '06', :method_name => :not_expired, :since => 1.year.ago, :attr => :updated_at
  end
end


class Person < ActiveRecord::Base
  belongs_to :company
end

full_company = Company.create(:name => "FullFeatured", :start_of_operations => "2012-01-01", :end_of_operations => "2012-02-02")
empty_company= Company.create(:start_of_operations => "2012-03-03", :end_of_operations => "2012-02-02")


person = Person.create(:name => "Test Fred", :employed_since => "2012-01-01")
person.company=full_company
person.save

empty_company.quality_test_states.create(:identifier => "01", :not_applicable => true)
empty_company.quality_test_states.create(:identifier => "02", :not_applicable => true)



