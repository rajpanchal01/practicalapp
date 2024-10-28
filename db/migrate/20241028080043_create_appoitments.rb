class CreateAppoitments < ActiveRecord::Migration[5.2]
  def change
    create_table :appointments do |t|
      t.references :doctor, foreign_key: { to_table: :users }, null: false
      t.references :patient, foreign_key: { to_table: :users }, null: false
      t.datetime :appointment_time, null: false
      t.datetime :end_time, null: false
      t.references :time_slot, foreign_key: true, null: false

      t.timestamps
    end

    # Index to prevent overlapping appointments on the same time for the same doctor
    add_index :appointments, [:doctor_id, :appointment_time, :end_time], unique: true, name: 'index_appointments_on_doctor_and_time'
  end
end
