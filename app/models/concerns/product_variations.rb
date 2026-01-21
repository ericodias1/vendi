# frozen_string_literal: true

module ProductVariations
  extend ActiveSupport::Concern

  # Tamanhos pré-definidos
  SIZES = [
    "1", "2", "3", "4", "6", "8", "10", "12", "14", "16",
    "P", "M", "G", "GG", "EG", "EGG", "G1", "G2", "G3"
  ].freeze

  # Cores pré-definidas
  COLORS = [
    "Branco", "Preto", "Cinza", "Bege", "Marrom", "Caramelo",
    "Vermelho", "Rosa", "Rosa Bebê", "Coral", "Salmão",
    "Azul", "Azul Marinho", "Azul Bebê", "Azul Claro", "Azul Turquesa",
    "Verde", "Verde Limão", "Verde Menta", "Verde Oliva",
    "Amarelo", "Amarelo Ouro", "Amarelo Limão",
    "Laranja", "Laranja Queimado",
    "Roxo", "Lilás", "Lavanda", "Violeta",
    "Dourado", "Prata", "Bronze",
    "Estampado", "Listrado", "Floral", "Bolinhas", "Xadrez",
    "Nude", "Pérola", "Creme", "Off-White", "Champagne"
  ].freeze

  class_methods do
    def available_sizes
      SIZES
    end

    def available_colors
      COLORS
    end
  end
end
