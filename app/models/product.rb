class Product < ApplicationRecord
  belongs_to :brand, optional: true
  has_and_belongs_to_many :categories
  has_many :order_items, dependent: :nullify
  has_one_attached :image

  before_validation :ensure_slug

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :featured, -> { where(featured: true) }
  scope :best_sellers, -> { where(best_seller: true) }
  scope :ordered, -> { order(:position, :name) }
  scope :low_stock, -> { where("stock_quantity <= low_stock_threshold") }
  scope :out_of_stock, -> { where(stock_quantity: ..0) }

  def in_stock?
    stock_quantity.to_i.positive?
  end

  def low_stock?
    stock_quantity.to_i <= low_stock_threshold.to_i
  end

  # Atomically reduce stock by `qty`, never below zero.
  def reduce_stock!(qty)
    self.class.where(id: id).update_all(["stock_quantity = GREATEST(stock_quantity - ?, 0)", qty.to_i])
  end

  # Sorting options exposed on the shop page. Keys match the ?sort= param.
  SORTS = {
    "newest"     => -> { order(created_at: :desc) },
    "price-asc"  => -> { order(price_cents: :asc) },
    "price-desc" => -> { order(price_cents: :desc) },
    "name"       => -> { order(:name) },
  }.freeze

  def self.sorted_by(key)
    (SORTS[key] || SORTS["name"]).call
  end

  def to_param = slug

  def price
    Money.new(price_cents)
  end

  # --- Virtual attributes for the admin form ---

  # Price entered/edited in euro; stored as integer cents.
  def price_eur
    price_cents.to_i / 100.0
  end

  def price_eur=(value)
    self.price_cents = (value.to_s.tr(",", ".").to_f * 100).round
  end

  # Weight entered/edited in kilograms; stored as integer grams.
  def weight_kg
    weight_grams.to_i / 1000.0
  end

  def weight_kg=(value)
    self.weight_grams = (value.to_s.tr(",", ".").to_f * 1000).round
  end

  # "Допълнителна информация" edited as one "Label = value" per line.
  def specs_text
    Array(specs).map { |label, value| "#{label} = #{value}" }.join("\n")
  end

  def specs_text=(text)
    self.specs = text.to_s.split(/\r?\n/).filter_map do |line|
      next if line.strip.empty?
      label, value = line.split("=", 2)
      [label.to_s.strip, value.to_s.strip] if value.present?
    end
  end

  private

  def ensure_slug
    return if slug.present?
    base = name.to_s.parameterize
    self.slug = base.presence || "product-#{SecureRandom.hex(4)}"
  end
end
