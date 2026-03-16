class BuildingTroopType < ApplicationRecord
  # Константы для доступных зданий и типов войск
  BUILDINGS = ['tc', 'north', 'south', 'west', 'east'].freeze
  TROOP_TYPES = ['fighter', 'archer', 'rider'].freeze
  
  # Валидации
  validates :building, presence: true, inclusion: { in: BUILDINGS }
  validates :slot, presence: true, inclusion: { in: [1, 2] }
  validates :troop_type, inclusion: { in: TROOP_TYPES }, allow_blank: true, allow_nil: true
  
  # Уникальность пары building + slot
  validates :building, uniqueness: { scope: :slot, message: "already has settings for this slot" }
  
  # Скоупы для удобства
  scope :for_slot, ->(slot) { where(slot: slot) }
  scope :manual, -> { where.not(troop_type: nil) }
  scope :auto, -> { where(troop_type: nil) }
  
  # Возвращает читаемое название здания (для логов)
  def display_name
    "#{building} (slot #{slot})"
  end
end