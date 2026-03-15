class CreateBuildingTroopTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :building_troop_types do |t|
      t.string :building
      t.string :troop_type

      t.timestamps
    end
    add_index :building_troop_types, :building, unique: true
  end
end
