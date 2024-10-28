module Api
  class TimeSlotsController < ApplicationController
    respond_to :json
    before_action :authenticated_user!
    before_action :check_doctor, only: [:create]

    def index
      @time_slots = TimeSlot.all
      render json: {data: @time_slots , status: 200, success: true, message: "Home page"}, status: :ok
    end

    def create
      time_slot = TimeSlot.new(time_slot_params)

      if time_slot.save
        render json: { status: 'success', time_slot: time_slot }, status: :created
      else
        render json: { status: 'error', errors: time_slot.errors.full_messages }, status: :unprocessable_entity
      end
    end


    private

    def time_slot_params
      params.permit(:for_date, :start_time, :end_time, :doctor_id)
    end
  end
end