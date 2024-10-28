module Api
  class HomeController < ApplicationController
    respond_to :json
    before_action :authenticated_user!

    def index
      #this page will return all the upcoming appointments for doctor or patient based on role
      render json: {data: User.find(1).appointments.upcoming, status: 200, success: true, message: "Home page"}, status: :ok
    end
  end
end
