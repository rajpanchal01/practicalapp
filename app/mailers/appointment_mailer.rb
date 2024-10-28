class AppointmentMailer < ApplicationMailer
  default from: 'no-reply@gmail.com'

  def reminder_email(appointment)
    @appointment = appointment
    @patient = appointment.patient
    mail(to: @patient.email, subject: "Appointment Reminder")
  end
end
