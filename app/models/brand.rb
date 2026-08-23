class Brand < ApplicationRecord
  has_many :products, dependent: :nullify

  before_validation :ensure_slug

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true

  scope :ordered, -> { order(:name) }

  def to_param = slug

  private

  def ensure_slug
    return if slug.present?
    base = name.to_s.parameterize
    self.slug = base.presence || "brand-#{SecureRandom.hex(4)}"
  end
end
