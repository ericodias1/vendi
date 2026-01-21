# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: "noreply@vendi.com.br"
  layout "mailer"
end
