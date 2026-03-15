class Distribution < ApplicationRecord
  belongs_to :player, optional: true
  
  validates :slot, presence: true, inclusion: { in: [1, 2] }
  validates :building, presence: true
  validates :role, presence: true, inclusion: { in: ['captain', 'participant'] }
  validates :allocated_troops, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :distribution_date, presence: true
  
  scope :for_date, ->(date = Date.current) { where(distribution_date: date) }
  scope :captains, -> { where(role: 'captain') }
  scope :participants, -> { where(role: 'participant') }
  
  def self.latest
    where(distribution_date: Date.current).order(:slot, :building)
  end
end