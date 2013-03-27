class CreateQualityTestStates < ActiveRecord::Migration
  def change
    create_table :quality_test_states do |t|
      t.string :identifier
      t.boolean :not_applicable
      t.integer :testable_id
      t.string :testable_type

      t.timestamps
    end
  end
end