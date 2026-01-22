# frozen_string_literal: true

module Searchable
  extend ActiveSupport::Concern

  included do
    scope :search, ->(term) {
      return all if term.blank?
      
      columns = searchable_columns
      return all if columns.blank?

      search_term = "%#{term.strip}%"
      conditions = columns.map { |col|
        "#{table_name}.#{col} ILIKE ?"
      }.join(" OR ")

      where(conditions, *([search_term] * columns.count))
    }
  end

  class_methods do
    def searchable_columns(*columns)
      if columns.any?
        @searchable_columns = columns.map(&:to_s)
      else
        @searchable_columns || []
      end
    end
  end
end
