require "data_quality/quality_test"
require "data_quality/quality_test_result"
require "data_quality/model"
require 'data_quality/quality_test_state'

ActiveRecord::Base.send(:include, DataQuality::Model)