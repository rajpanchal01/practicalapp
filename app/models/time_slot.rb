class TimeSlot < ApplicationRecord
	belongs_to :doctor, class_name: "User", foreign_key: :doctor_id

  scope :by_doctor_name, ->(name) {
    joins(:doctor).where("users.first_name ILIKE ? OR users.last_name ILIKE ?", "%#{name}%", "%#{name}%").order(:start_time)
  }

  scope :next_availability, ->(name = nil) {
    scope = where("for_date >= ? AND start_time > ?", Date.today, Time.now).order(:start_time)
    name ? scope.by_doctor_name(name) : scope
  }
  
	validates :for_date, :start_time, :end_time, :doctor_id, presence: true
  validate :no_overlapping_time_slots

  has_many :appointments

	private

  # Validation to ensure no overlapping time slots for the same doctor on the same day
  def no_overlapping_time_slots
    overlapping_time_slot = TimeSlot.where(doctor_id: doctor_id, for_date: for_date)
      .where.not(id: id) # Exclude current record in case of update
      .where("(start_time < ? AND end_time > ?) OR (start_time < ? AND end_time > ?)", end_time, start_time, end_time, start_time)
      .exists?

    if overlapping_time_slot
      errors.add(:base, "Doctor already has an availability during this time period.")
    end
  end
end
