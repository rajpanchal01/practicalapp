module Api
  class AppointmentsController < ApplicationController
    respond_to :json
    before_action :authenticated_user!
    before_action :check_patient, only: [:create]

    def index
      # Fetch all available time slots with associated doctors,
      # excluding those that have been booked.
      @available_time_slots = TimeSlot.joins(:doctor)
            .left_outer_joins(:appointments)
            .where("time_slots.for_date >= ?", Date.today)
            .includes(:doctor).order(:start_time)
    
      # Filter by doctor's name if provided
      if params[:doctor_name].present?
        @available_time_slots = @available_time_slots.where("users.first_name ILIKE :name OR users.last_name ILIKE :name", name: "%#{params[:doctor_name]}%")
      end
    
      # Group by doctor and determine available slots
      result = @available_time_slots.group_by(&:doctor_id).map do |doctor_id, slots|
        doctor = slots.first.doctor
        
        available_slots = slots.flat_map do |slot|
          # Get all appointments within the current slot
          overlapping_appointments = slot.appointments.select do |appointment|
            appointment.appointment_time >= slot.start_time && appointment.appointment_time < slot.end_time
          end
    
          # Initialize an array to hold available time segments
          available_time_segments = []
          start_time = slot.start_time
    
          # Check for gaps before each appointment
          overlapping_appointments.each do |appointment|
            # If there's a gap before the appointment
            if start_time < appointment.appointment_time
              available_time_segments << {
                for_date: slot.for_date,
                start_time: start_time,
                end_time: appointment.appointment_time
              }
            end
    
            # Move the start time to the end of the current appointment
            start_time = appointment.appointment_time + 1.hour # Assuming appointments are 1 hour long
          end
    
          # Check if there's time left after the last appointment in the slot
          if start_time < slot.end_time
            available_time_segments << {
              for_date: slot.for_date,
              start_time: start_time,
              end_time: slot.end_time
            }
          end
    
          # Return the segments that are available
          available_time_segments
        end
    
        # Determine the next available slot
        next_available_slot = available_slots.find { |segment| Time.current < segment[:start_time] }
    
        {
          doctor_name: doctor.full_name, # Assuming you have a full_name method in User model
          available_slots: available_slots,
          next_available_slot: next_available_slot ? {
            for_date: next_available_slot[:for_date],
            start_time: next_available_slot[:start_time],
          } : nil
        }
      end
    
      render json: result
    end

    def create
      @appointment = Appointment.new(appointment_params)
      time_slot = TimeSlot.find_by("doctor_id = ? AND start_time <= ? AND end_time > ?",params[:doctor_id], appointment_params[:appointment_time], appointment_params[:appointment_time])
      if time_slot
        @appointment = Appointment.new(appointment_params.merge(time_slot_id: time_slot.id))
        if @appointment.save
          render json: { message: "Appointment booked successfully.", data: @appointment }, status: :created
        else
          render json: { errors: @appointment.errors.full_messages }, status: :unprocessable_entity
        end
      else
        render json: { error: "No available time slot found for the selected appointment time." }, status: :unprocessable_entity
      end
    end

    
    private

    # Helper to format the time slot with doctor's name
    def format_time_slot(slot)
      return unless slot

      {
        id: slot.id,
        for_date: slot.for_date,
        start_time: slot.start_time,
        end_time: slot.end_time,
        doctor_name: slot.doctor&.first_name + " " + slot.doctor&.last_name
      }
    end
  
    def appointment_params
      params.permit(:doctor_id, :patient_id, :appointment_time)
    end
  
  end
end