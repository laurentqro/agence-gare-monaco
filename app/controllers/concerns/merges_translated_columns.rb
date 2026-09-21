# Admin forms edit the French value of columns that store every locale in one
# JSON hash. Assigning the submitted value would replace the whole column and
# destroy the translated locales, which the translator cannot always rebuild
# (API outage, spend cap). Merge into the stored hash instead.
#
# With drop_blank: true, blank values are removed from the MERGED hash. A
# field submitted empty overwrites the stored key and is then dropped, so
# clearing a per-locale override removes it (SEO overrides); the stored keys
# for other locales are untouched.
module MergesTranslatedColumns
  extend ActiveSupport::Concern

  private

  def merge_translated_columns(permitted, record, columns, drop_blank: false)
    columns.each do |column|
      submitted = permitted[column]
      next if submitted.nil?

      existing = record&.public_send(column) || {}
      merged = existing.merge(submitted.to_h)
      merged = merged.reject { |_locale, value| value.blank? } if drop_blank
      permitted[column] = merged
    end

    permitted
  end
end
