# frozen_string_literal: true

module ReportExportable
  extend ActiveSupport::Concern

  included do
    # Helpers para formatar dados para exportação
  end

  private

  def export_csv(data, filename)
    # Stub - implementação futura
    # TODO: Implementar exportação CSV usando CSV do Ruby
    raise NotImplementedError, "Exportação CSV será implementada em breve"
  end

  def export_pdf(data, filename)
    # Stub - implementação futura
    # TODO: Implementar exportação PDF usando prawn
    raise NotImplementedError, "Exportação PDF será implementada em breve"
  end

  def send_report_email(data, email, format)
    # Stub - implementação futura
    # TODO: Implementar envio por email usando ActionMailer
    raise NotImplementedError, "Envio por email será implementado em breve"
  end

  def format_report_data_for_export(data, format)
    # Helper para formatar dados antes da exportação
    # TODO: Implementar formatação específica por formato
    data
  end
end
