class ApplicationController < ActionController::API
	def authenticated_user!
    if request.headers["HTTP_AUTH_TOKEN"].present?
      device_detail = DeviceDetail.find_by(authentication_token: request.headers["HTTP_AUTH_TOKEN"])
      if device_detail.present?
        @current_user = device_detail.user
      else
        render json: { errors: "Token is invalid" }, status: :ok
      end
    else
      render json: { errors: "Authentication token required" }, status: :ok
    end
  end

  def check_doctor
    @current_user.roles.include?(:doctor)
  end
  
  def check_patient 
    @current_user.roles.include?(:patient)
  end
end
