class SessionsController < ApplicationController
  # Autenticación básica por sesión/cookies.
  # Sin JWT ni auth API. Sin roles/permisos.
  def new
    redirect_to root_path if logged_in?
  end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)
    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to root_path, notice: 'Sesión iniciada'
    else
      flash.now[:alert] = 'Correo o contraseña inválidos'
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: 'Sesión cerrada'
  end
end
