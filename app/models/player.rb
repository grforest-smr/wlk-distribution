class Player < ApplicationRecord
  validates :nickname, presence: true
  validates :troop_type, presence: true
  validates :level, presence: true
  validates :march_size, presence: true, numericality: { greater_than: 0 }
  
  # Связи
  has_many :distributions, dependent: :nullify
end