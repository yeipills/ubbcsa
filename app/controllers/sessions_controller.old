# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:email])
    if user
      Rails.logger.info "User found: #{user.inspect}"
      if user.authenticate(params[:password])
        Rails.logger.info "Authentication successful"
        session[:user_id] = user.id
        redirect_to main_path, notice: 'Logged in successfully'
      else
        Rails.logger.info "Authentication failed"
        flash.now[:alert] = 'Invalid email or password'
        render :new
      end
    else
      Rails.logger.info "User not found"
      flash.now[:alert] = 'Invalid email or password'
      render :new
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to login_path, notice: 'Logged out successfully'
  end
end
