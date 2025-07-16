class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  #helper :all

=begin
  helper_method :current_user, :logged_in?

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]  
  end

  def logged_in?
    !!current_user
  end

  def require_user
    if !logged_in
      flash[:danger] = 'You must be logged in to perform that action'
      redirect_to root_path
    end
  end
=end

  def configure_permitted_parameters
    #devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:username, :email, :password, :password_confirmation)}
    #devise_parameter_sanitizer.permit(:sign_in, keys: [:username])
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
    devise_parameter_sanitizer.permit(:account_update, keys: [:username])
  end

  def start_vote_timer
    #session[:vote_timer_status] = 'r' #running 
    session[:vote_timer] = Time.now
  end

  def stop_vote_timer
    #session[:vote_timer_status] = 'i' #idle 
    tn = Time.now.utc
    tp = Time.parse(session[:vote_timer])
    dif = tn - tp
    rnd = dif.round 
    ##(Time.now - session[:vote_timer]).round
  end

  def start_create_timer
    #session[:create_timer_status] = 'r' #running 
    session[:create_timer] = Time.now
  end

  def stop_create_timer
    #session[:create_timer_status] = 'i' #idle 
    tn = Time.now.utc
    tp = Time.parse(session[:create_timer])
    dif = tn - tp
    rnd = dif.round 
    ##(Time.now - session[:create_timer]).round
  end

end
