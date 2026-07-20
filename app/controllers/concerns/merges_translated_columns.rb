# Admin forms edit the French value of columns that store every locale in one
# JSON hash. Assigning the submitted value would replace the whole column and
# destroy the translated locales, which the translator cannot always rebuild
# (API outage, spend cap). Merge into the stored hash instead.
module MergesTranslatedColumns
  extend ActiveSupport::Concern

  private

  def merge_translated_columns(permitted, record, columns)
    columns.each do |column|
      submitted = permitted[column]
      next if submitted.nil?

      existing = record&.public_send(column) || {}
      permitted[column] = existing.merge(submitted.to_h)
    end

    permitted
  end
end
