module DataQuality
  class QualityTestState < ActiveRecord::Base
    belongs_to :testable, :polymorphic => true
  end
end
