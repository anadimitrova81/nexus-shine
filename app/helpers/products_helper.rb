module ProductsHelper
  SORT_LABELS = {
    "name"       => "По име",
    "newest"     => "Най-нови",
    "price-asc"  => "Цена: ниска → висока",
    "price-desc" => "Цена: висока → ниска",
  }.freeze

  def sort_options
    SORT_LABELS.map { |value, label| [label, value] }
  end

  # Bulgarian count label: 1 → "1 продукт", else "N продукта".
  def pluralize_bg(count, singular, plural)
    "#{count} #{count == 1 ? singular : plural}"
  end
end
