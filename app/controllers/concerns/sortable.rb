# Server-side, injection-safe column sorting driven by `?sort=&direction=`.
#
# Controllers declare an allow-list of sortable columns and call `sort_scope`
# to order a relation. Unknown columns fall back to the first allowed column,
# so a malicious `sort` param can never reach SQL. The current sort state is
# exposed to views via the `current_sort` / `current_direction` helpers so
# header links can render direction toggles and arrows.
module Sortable
  extend ActiveSupport::Concern

  included do
    helper_method :current_sort, :current_direction if respond_to?(:helper_method)
  end

  private

  # @param relation [ActiveRecord::Relation]
  # @param columns [Array<String,Symbol>] allow-listed, sortable column names
  # @param default [String,Symbol] column used when none/invalid is requested
  def sort_scope(relation, columns:, default: nil)
    allowed = columns.map(&:to_s)
    column = allowed.include?(params[:sort].to_s) ? params[:sort].to_s : (default || allowed.first).to_s
    relation.order(Arel.sql("#{relation.table_name}.#{column}") => current_direction)
  end

  def current_sort
    params[:sort].presence
  end

  def current_direction
    params[:direction].to_s == "desc" ? "desc" : "asc"
  end
end
