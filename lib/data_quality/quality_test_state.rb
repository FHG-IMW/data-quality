module DataQuality
  class QualityTestState < ActiveRecord::Base
    attr_accessible :identifier, :not_applicable, :testable_id, :testable_type

    belongs_to :testable, :polymorphic => true
  end
end
