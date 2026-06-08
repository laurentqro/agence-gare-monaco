module AdminHelper
  # Minimal inline-SVG icon set for admin action buttons. Each value is the
  # inner markup of a 20x20 stroke icon (Heroicons outline paths).
  ACTION_ICONS = {
    eye: '<path stroke-linecap="round" stroke-linejoin="round" d="M2.036 12.322a1.012 1.012 0 010-.644C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178z" /><path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />',
    pencil: '<path stroke-linecap="round" stroke-linejoin="round" d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931z" />',
    document: '<path stroke-linecap="round" stroke-linejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m2.25 0H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z" />',
    share: '<path stroke-linecap="round" stroke-linejoin="round" d="M7.217 10.907a2.25 2.25 0 100 2.186m0-2.186c.18.324.283.696.283 1.093s-.103.77-.283 1.093m0-2.186l9.566-5.314m-9.566 7.5l9.566 5.314m0 0a2.25 2.25 0 103.935 2.186 2.25 2.25 0 00-3.935-2.186zm0-12.814a2.25 2.25 0 103.933-2.185 2.25 2.25 0 00-3.933 2.185z" />',
    trash: '<path stroke-linecap="round" stroke-linejoin="round" d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" />'
  }.freeze

  # Renders a compact icon + label action button for admin tables.
  #
  #   admin_action_link t("admin.shared.view"), admin_property_path(p), icon: :eye
  #   admin_action_link t("admin.shared.delete"), admin_property_path(p),
  #     icon: :trash, variant: :danger, data: { turbo_method: :delete }
  #
  # @param variant [:default, :danger]
  def admin_action_link(label, url, icon:, variant: :default, data: {}, **options)
    svg = ACTION_ICONS.fetch(icon)
    colors = case variant
             when :danger then "text-red-600 hover:bg-red-50 hover:text-red-700"
             else "text-gray-600 hover:bg-navy/5 hover:text-navy"
             end

    link_to url,
            data: data,
            class: "inline-flex items-center gap-1.5 rounded-md px-2.5 py-1.5 text-xs font-medium transition-colors #{colors}",
            **options do
      icon_svg(svg) + content_tag(:span, label)
    end
  end

  # Whether a sidebar nav link should be marked active for the current path.
  #
  # By default a link is active when the current path equals the link path or
  # is nested beneath it (so /admin/articles/5/edit highlights "Articles").
  # Pass exact: true for the dashboard root, whose path is a prefix of every
  # other admin page.
  def admin_nav_active?(current_path, link_path, exact: false)
    return current_path == link_path if exact

    current_path == link_path || current_path.start_with?("#{link_path}/")
  end

  # CSS classes for a sidebar nav link, adding an active highlight when the
  # link matches the current request path.
  def admin_nav_link_class(link_path, exact: false)
    base = "flex items-center gap-3 px-3 py-2 rounded"
    if admin_nav_active?(request.path, link_path, exact: exact)
      "#{base} bg-white/15 font-semibold"
    else
      "#{base} hover:bg-white/10"
    end
  end

  private

  def icon_svg(inner)
    raw <<~SVG
      <svg class="h-4 w-4 shrink-0" fill="none" viewBox="0 0 24 24" stroke-width="1.6" stroke="currentColor" aria-hidden="true">#{inner}</svg>
    SVG
  end
end
