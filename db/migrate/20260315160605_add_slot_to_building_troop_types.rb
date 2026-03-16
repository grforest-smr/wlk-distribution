class AddSlotToBuildingTroopTypes < ActiveRecord::Migration[8.0]
  def change
    # Добавляем поле slot (по умолчанию 1)
    add_column :building_troop_types, :slot, :integer, default: 1, null: false

    # Удаляем старый уникальный индекс на building
    remove_index :building_troop_types, :building if index_exists?(:building_troop_types, :building)

    # Добавляем новый составной уникальный индекс (building + slot)
    add_index :building_troop_types, [:building, :slot], unique: true
  end
end