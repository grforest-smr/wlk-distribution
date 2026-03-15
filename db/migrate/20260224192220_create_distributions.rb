class CreateDistributions < ActiveRecord::Migration[8.0]
  def change
    create_table :distributions do |t|
      t.integer :slot
      t.string :building
      t.references :player, null: false, foreign_key: true
      t.string :role
      t.bigint :allocated_troops
      t.date :distribution_date

      t.timestamps
    end
  end
end
