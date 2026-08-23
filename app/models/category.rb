class Category < ApplicationRecord
  has_and_belongs_to_many :products

  before_validation :ensure_slug

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true

  scope :ordered, -> { order(:position, :name) }

  def to_param = slug

  def product_count
    products.active.count
  end

  private

  def ensure_slug
    return if slug.present?
    base = name.to_s.parameterize
    self.slug = base.presence || "category-#{SecureRandom.hex(4)}"
  end
end
