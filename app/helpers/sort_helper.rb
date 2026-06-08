module SortHelper
  # Renders a table-header sort link. Clicking toggles asc/desc for `column`
  # and (when `frame` is given) updates only that Turbo Frame, so surrounding
  # state such as an email preview is preserved.
  #
  #   sort_link("company", t("admin.contacts.table.company"),
  #             url: admin_contacts_path, frame: "contacts_table")
  def sort_link(column, label, url:, frame: nil)
    column = column.to_s
    active = current_sort == column
    next_direction = (active && current_direction == "asc") ? "desc" : "asc"
    arrow = active ? (current_direction == "asc" ? " ↑" : " ↓") : ""

    # Preserve any active filter/search params so sort composes with them.
    carried = request.query_parameters.except("sort", "direction")
    query = carried.merge(sort: column, direction: next_direction)
    href = url + (url.include?("?") ? "&" : "?") + query.to_query

    link_to "#{label}#{arrow}".html_safe, href,
            data: frame ? { turbo_frame: frame } : {},
            class: "inline-flex items-center hover:text-navy#{active ? " text-navy font-semibold" : ""}"
  end
end
