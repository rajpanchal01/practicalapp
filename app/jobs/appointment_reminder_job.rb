class AppointmentReminderJob < ApplicationJob
  queue_as :default

  def perform(appointment_id)
    appointment = Appointment.find(appointment_id)
    AppointmentMailer.reminder_email(appointment).deliver_now if appointment.appointment_time > Time.current
  end
end
