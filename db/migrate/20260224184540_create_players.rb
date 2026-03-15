class CreatePlayers < ActiveRecord::Migration[8.0]
  def change
    create_table :players do |t|
      t.string :nickname
      t.string :alliance
      t.string :troop_type
      t.string :level
      t.bigint :march_size
      t.bigint :group_attack
      t.bigint :troop_power
      t.string :slot
      t.string :wants_captain
      t.datetime :registration_time
      t.inet :ip_address

      t.timestamps
    end
    add_index :players, :nickname
  end
end
