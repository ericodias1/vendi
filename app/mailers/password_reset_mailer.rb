# frozen_string_literal: true

class PasswordResetMailer < ApplicationMailer
  def reset_password(user)
    @user = user
    @reset_url = edit_password_reset_url(token: user.password_reset_token)
    
    mail(
      to: user.email,
      subject: "Redefinição de senha - Vendi Gestão"
    )
  end
end
