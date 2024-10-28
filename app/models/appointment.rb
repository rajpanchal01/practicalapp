class Appointment < ApplicationRecord
  #associations
  belongs_to :doctor, class_name: "User", foreign_key: :doctor_id
  belongs_to :patient, class_name: "User", foreign_key: :patient_id
  belongs_to :time_slot

  #scopes
  scope :upcoming, -> { where("appointment_time > ?", Time.current) }

  #validations
  before_validation :set_end_time
  validate :appointment_within_time_slot
  validate :no_overlapping_appointments
  validate :time_slot_availability

  #callback for email
  after_create :schedule_reminder

  private

  def time_slot_availability
    unless time_slot && time_slot.start_time <= appointment_time && time_slot.end_time >= appointment_time
      errors.add(:base, "Selected time slot is not available.")
    end
  end

  #email reminder for patient
  def schedule_reminder
    reminder_time = appointment_time - 30.minutes
    AppointmentReminderJob.set(wait_until: reminder_time).perform_later(id)
  end

  def set_end_time
    self.end_time = appointment_time + 1.hour if appointment_time.present?
  end

  def appointment_within_time_slot
    if time_slot.present? && appointment_time.present?
      unless appointment_time.between?(time_slot.start_time, time_slot.end_time - 1.hour) && end_time <= time_slot.end_time
        errors.add(:appointment_time, "must be within the doctor's available time slot.")
      end
    else
      errors.add(:time_slot, "must be selected for the appointment.")
    end
  end

  def no_overlapping_appointments
    if doctor && appointment_time.present? && end_time.present?
      overlapping_appointment = doctor.appointments
                                      .where(time_slot: time_slot)
                                      .where.not(id: id)
                                      .where("appointment_time < ? AND end_time > ?", end_time, appointment_time)
      if overlapping_appointment.exists?
        errors.add(:base, "This appointment overlaps with an existing appointment.")
      end
    end
  end
end
