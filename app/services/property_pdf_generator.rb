class PropertyPdfGenerator
  NAVY = "#090956"
  ACCENT = "#6E8297"
  TEXT_COLOR = "#212529"

  LOGO_PATH = Rails.root.join("app/assets/images/logo.png")
  CIM_LOGO_PATH = Rails.root.join("app/assets/images/logo-cim.png")
  FONT_DIR = Rails.root.join("app/assets/fonts")

  def initialize(property, locale: :fr, include_logo: true)
    @property = property
    @locale = locale.to_sym
    @include_logo = include_logo
    @dependencies = {}
    @qr_png = generate_qr_png(property_url)
  end

  def generate
    typst_source = build_template
    fonts = load_fonts
    Typst(body: typst_source, dependencies: @dependencies, fonts: fonts).compile(:pdf).pages.first
  end

  private

  def build_template
    <<~TYPST
      #{page_setup}
      #{header_footer_functions}

      // ── Page 1: Content ──
      #{hero_image_markup}
      #{title_markup}
      #{badges_markup}
      #{content_columns_markup}

      #{photo_pages_markup}
    TYPST
  end

  def page_setup
    <<~TYPST
      #set page(
        paper: "a4",
        margin: (top: 40mm, bottom: 35mm, left: 15mm, right: 15mm),
        header: context {
          set text(font: "Montserrat", size: 6.5pt, fill: rgb("#{ACCENT}"))
          grid(
            columns: (1fr, auto, auto),
            align: (left + horizon, right + horizon, right + horizon),
            column-gutter: 8pt,
            #{logo_header_markup}
            [
              #{escape(t("pdf_brochure.contact_address"))} \\ #{escape(t("pdf_brochure.contact_city"))} \\ #{escape(t("pdf_brochure.contact_phone"))} \\ #{escape(t("pdf_brochure.contact_email"))} \\ #{escape(t("pdf_brochure.contact_website"))}
            ],
            #{qr_code_markup}
          )
          v(6pt)
          line(length: 100%, stroke: 0.4pt + rgb("#{ACCENT}"))
        },
        footer: {
          line(length: 100%, stroke: 0.4pt + rgb("#{ACCENT}"))
          v(6pt)
          grid(
            columns: (auto, 1fr),
            gutter: 10pt,
            #{cim_logo_markup}
            {
              set text(font: "Montserrat", fill: rgb("#{ACCENT}"))
              text(size: 6.5pt, weight: "bold", [#{escape(t("pdf_brochure.fees_line"))}])
              v(2pt)
              text(size: 5.5pt, [#{escape(t("pdf_brochure.disclaimer"))}])
            },
          )
        },
      )
      #set text(font: "Montserrat", size: 9pt, fill: rgb("#{TEXT_COLOR}"))
      #set smartquote(enabled: false)
      #set par(leading: 0.6em)
    TYPST
  end

  def header_footer_functions
    "" # Using page header/footer directly
  end

  def logo_header_markup
    if @include_logo && File.exist?(LOGO_PATH)
      add_dependency("logo.png", LOGO_PATH)
      'image("logo.png", width: 45mm),'
    else
      "[],"
    end
  end

  def qr_code_markup
    if @qr_png
      @dependencies["qr.png"] = @qr_png
      'image("qr.png", width: 19mm),'
    else
      "[],"
    end
  end

  def cim_logo_markup
    if File.exist?(CIM_LOGO_PATH)
      add_dependency("logo-cim.png", CIM_LOGO_PATH)
      'image("logo-cim.png", width: 12mm),'
    else
      "[],"
    end
  end

  def hero_image_markup
    cover = @property.cover_image
    return "" unless cover

    image_data = fetch_image(cover.large_url || cover.remote_url)
    return "" unless image_data

    @dependencies["hero.jpg"] = image_data
    <<~TYPST
      #image("hero.jpg", width: 100%)
      #v(6pt)
    TYPST
  rescue StandardError
    ""
  end

  def title_markup
    title = @property.title_for(@locale)
    <<~TYPST
      #align(center)[
        #text(size: 16pt, weight: "bold", fill: rgb("#{NAVY}"))[#{escape(title)}]
      ]
    TYPST
  end

  def badges_markup
    badges = []
    badges << t("pdf_brochure.off_market_badge") if @property.off_market?
    badges << t("pdf_brochure.exclusivity_badge") if @property.exclusivity?
    return "" if badges.empty?

    <<~TYPST
      #v(3pt)
      #align(center)[
        #text(size: 9pt, weight: "bold", fill: rgb("#{ACCENT}"))[#{escape(badges.join("  |  "))}]
      ]
    TYPST
  end

  def content_columns_markup
    description = @property.description_for(@locale)
    details = detail_rows

    return "" if description.blank? && details.empty?

    clean_desc = description.present? ? strip_html(description) : ""
    desc_size = if clean_desc.length > 1200
      "7pt"
    elsif clean_desc.length > 800
      "7.5pt"
    elsif clean_desc.length > 500
      "8pt"
    else
      "9pt"
    end

    desc_markup = if description.present?
      paragraphs = format_description(description)
      paragraphs.map.with_index { |para, i|
        if i == 0
          "#text(weight: \"bold\", style: \"italic\")[#{escape(para)}]"
        else
          escape(para)
        end
      }.join("\n\n")
    else
      ""
    end

    table_markup = if details.any?
      row_count = details.length
      regular_cells = details[0...-2].map { |label, value|
        "[#{escape(label)}], align(right)[#{escape(value)}],"
      }.join("\n            ")

      highlight_cells = details[-2..].map { |label, value|
        "text(weight: \"bold\")[#{escape(label)}], align(right, text(weight: \"bold\")[#{escape(value)}]),"
      }.join("\n            ")

      <<~TYPST
        #block(
          radius: 4pt,
          clip: true,
        )[
          #set text(size: 8pt, fill: white)
          #table(
            columns: (1fr, auto),
            inset: (x: 16pt, y: 7pt),
            stroke: none,
            fill: (_, row) => if row >= #{row_count - 2} { rgb("#{NAVY}").darken(15%) } else { rgb("#{NAVY}") },
            #{regular_cells}
            #{highlight_cells}
          )
        ]
      TYPST
    else
      ""
    end

    <<~TYPST
      #v(10pt)
      #grid(
        columns: (1fr, 45%),
        gutter: 24pt,
        [
          #set text(size: #{desc_size})
          #{desc_markup}
        ],
        [
          #{table_markup}
        ],
      )
    TYPST
  end

  def photo_pages_markup
    images = @property.property_images.where(is_plan: false).order(:position)
    cover = @property.cover_image
    photo_list = images.reject { |img| img.id == cover&.id }

    plans = @property.property_images.where(is_plan: true).order(:position)
    plan_list = plans.reject { |img| img.id == cover&.id }

    all_images = photo_list + plan_list
    return "" if all_images.empty?

    pages = []
    all_images.each_slice(2).with_index do |pair, page_idx|
      image_markups = pair.each_with_index.filter_map do |img, i|
        begin
          image_data = fetch_image(img.large_url || img.remote_url)
          next unless image_data

          key = "gallery_#{page_idx}_#{i}.jpg"
          @dependencies[key] = image_data
          <<~TYPST
            #align(center)[
              #image("#{key}", width: 85%, height: 45%, fit: "contain")
            ]
          TYPST
        rescue StandardError
          nil
        end
      end

      next if image_markups.empty?

      pages << <<~TYPST
        #pagebreak()
        #{image_markups.join("\n#v(12pt)\n")}
      TYPST
    end

    pages.join("\n")
  end

  # ── Helpers ──

  def detail_rows
    rows = []
    sqm = t("pdf_brochure.sqm")

    rows << [ t("property_detail.building"), @property.building.name ] if @property.building.present?
    rows << [ t("property_detail.type"), @property.property_type.capitalize ] if @property.property_type.present?
    rows << [ t("property_detail.living_area"), format_area(@property.living_area, sqm) ] if @property.living_area.present?
    rows << [ t("property_detail.total_area"), format_area(@property.total_area, sqm) ] if @property.total_area.present?
    rows << [ t("property_detail.terrace_area"), format_area(@property.terrace_area, sqm) ] if @property.terrace_area.present?
    rows << [ t("property_detail.land_area"), format_area(@property.land_area, sqm) ] if @property.land_area.present?
    rows << [ t("property_detail.garden_area"), format_area(@property.garden_area, sqm) ] if @property.garden_area.present?
    rows << [ t("property_detail.rooms"), @property.num_rooms.to_s ] if @property.num_rooms.present?
    rows << [ t("property_detail.bedrooms"), @property.num_bedrooms.to_s ] if @property.num_bedrooms.present?
    rows << [ t("property_detail.bathrooms"), @property.num_bathrooms.to_s ] if @property.num_bathrooms.present?
    rows << [ t("property_detail.parkings"), @property.num_parkings.to_s ] if @property.num_parkings.present?
    rows << [ t("property_detail.cellars"), @property.num_cellars.to_s ] if @property.num_cellars.present?
    rows << [ t("property_detail.floor"), @property.floor.to_s ] if @property.floor.present?

    # Reference and price at the bottom, bold
    rows << [ t("property_detail.reference"), @property.reference ]

    if @property.price.present?
      price_text = "#{@property.formatted_price} \u20AC"
      price_text += t("pdf_brochure.per_month") if @property.transaction_type == "rental"
      rows << [ t("pdf_brochure.price_label"), price_text ]
    else
      rows << [ t("pdf_brochure.price_label"), t("pdf_brochure.price_on_request") ]
    end

    rows
  end

  def format_area(value, unit)
    formatted = value == value.to_i ? value.to_i.to_s : format("%.2f", value)
    "#{formatted} #{unit}"
  end

  def format_description(description)
    clean = strip_html(description)
    clean.split(/\n+/).reject(&:blank?).map(&:strip)
  end

  def property_url
    props = I18n.t("routes.properties", locale: @locale)
    slug = @property.slug_for(@locale)
    prefix = @locale == :fr ? "" : "/#{@locale}"
    "#{SeoHelper::SITE_HOST}#{prefix}/#{props}/#{@property.id}-#{slug}"
  end

  def generate_qr_png(url)
    qr = RQRCode::QRCode.new(url)
    qr.as_png(size: 300, border_modules: 1, color: "6E8297").to_s.force_encoding("UTF-8")
  rescue StandardError
    nil
  end

  def fetch_image(url)
    return nil if url.blank?
    URI.parse(url).open.read.force_encoding("UTF-8")
  rescue StandardError
    nil
  end

  def add_dependency(name, path)
    @dependencies[name] = File.binread(path.to_s).force_encoding("UTF-8")
  end

  def strip_html(html)
    text = html.to_s
    # Decode &nbsp; before sanitizing (sanitizer doesn't handle it)
    text = text.gsub("&nbsp;", " ")
    # Convert <br> and block-closing tags to newlines
    text = text.gsub(/<br\s*\/?>/, "\n")
    text = text.gsub(%r{</(?:p|div|li|h[1-6])>}i, "\n")
    # Convert bullet list items to lines with bullet prefix
    text = text.gsub(/<li[^>]*>/i, "\n- ")
    # Strip remaining tags and decode HTML entities
    text = Rails::HTML5::FullSanitizer.new.sanitize(text)
    # Collapse runs of spaces (but preserve newlines)
    text = text.gsub(/[^\S\n]+/, " ")
    # Collapse 3+ consecutive newlines to 2
    text = text.gsub(/\n{3,}/, "\n\n")
    text.strip
  end

  def escape(text)
    # Escape Typst special characters: # * _ ` @ $ \ < > [ ] ( ) " ~
    text.to_s
      .gsub("\\", "\\\\\\\\")
      .gsub("#", "\\#")
      .gsub("*", "\\*")
      .gsub("_", "\\_")
      .gsub("`", "\\`")
      .gsub("@", "\\@")
      .gsub("$", "\\$")
      .gsub("<", "\\<")
      .gsub(">", "\\>")
      .gsub("~", "\\~")
  end

  def t(key)
    I18n.t(key, locale: @locale)
  end

  def load_fonts
    fonts = {}
    Dir.glob(FONT_DIR.join("*.ttf")).each do |path|
      fonts[File.basename(path)] = File.binread(path).force_encoding("UTF-8")
    end
    fonts
  end
end
