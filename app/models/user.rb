class User < ApplicationRecord
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum status: { active: 0, disabled: 1, unverified: 2, compliant: 3, rejected: 4 }

  has_many :device_details, dependent: :destroy
  has_many :time_slots, foreign_key: :doctor_id, dependent: :destroy
  # For doctors, linking to appointments where the user is the doctor
  has_many :appointments, foreign_key: :doctor_id, class_name: "Appointment"

  # For patients, linking to appointments where the user is the patient
  has_many :patient_appointments, foreign_key: :patient_id, class_name: "Appointment"

  def full_name
    first_name + " " + last_name
  end
end
