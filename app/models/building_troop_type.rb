class BuildingTroopType < ApplicationRecord
  validates :building, presence: true, uniqueness: true
  validates :troop_type, inclusion: { in: ['fighter', 'archer', 'rider', ''] }, allow_blank: true
  
  BUILDINGS = ['tc', 'north', 'south', 'west', 'east']
  validates :building, inclusion: { in: BUILDINGS }, allow_blank: true
end