# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: "nao-responda@vendigestao.com.br"
  layout "mailer"
end
