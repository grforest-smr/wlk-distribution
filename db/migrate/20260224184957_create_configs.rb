class CreateConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :configs do |t|
      t.string :key
      t.text :value

      t.timestamps
    end
    add_index :configs, :key, unique: true
  end
end
