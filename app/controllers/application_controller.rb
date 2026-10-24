class ApplicationController < ActionController::Base
  # Autenticación por sesión/cookies. Forma básica de permitir acceso a dashboard
  # Solo se revisa autenticación para acceder, sin roles/permisos por ahora.
  helper_method :current_user, :logged_in?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    return if logged_in?
    redirect_to login_path, alert: 'Debes iniciar sesión'
  end
end
