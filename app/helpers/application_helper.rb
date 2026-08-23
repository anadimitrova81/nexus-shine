module ApplicationHelper
  COMPANY = {
    name: "Nexus Shine",
    legal: "Nexus OOD",
    phone_display: "+359 898 225 825",
    phone_href: "+359898225825",
    email: "sales@nexus-shine.com",
    office_email: "office@nexus-shine.com",
    city: "Пловдив",
    postal_code: "4000",
    facebook: "https://www.facebook.com/",
  }.freeze

  def company = COMPANY

  # Brand slugs that have a logo asset in app/assets/images/brands/.
  BRAND_LOGOS = %w[era-111 turbopax power-1].freeze

  # Renders a brand's logo image when one exists, otherwise nil (callers fall
  # back to the brand name text).
  def brand_logo_tag(brand, **options)
    return nil unless brand && BRAND_LOGOS.include?(brand.slug)
    image_tag "brands/#{brand.slug}.png", alt: brand.name, **options
  end

  # Product slugs that have a packshot in app/assets/images/products/.
  PRODUCT_IMAGES = %w[
    turbopax-polish-gel stain-remover tire parfume-my-todays carpet-shampoo
    eengine-and-rim turbopax-torpedo auto-shampoo multi-ekinoze auto-foam
    power-1-modified-spray turbopax-auto-detail-cleaner
  ].freeze

  # Static packshot asset path for a product, or nil if none exists (callers
  # then fall back to the attached image or a placeholder).
  def product_image_source(product)
    "products/#{product.slug}.png" if product && PRODUCT_IMAGES.include?(product.slug)
  end

  # Renders a product description, turning short standalone label lines that end
  # with a colon (e.g. "Предимства:", "Приложение:", "Начин на употреба:") into
  # accented sub-headings, and everything else into paragraphs.
  def formatted_description(text)
    return "".html_safe if text.blank?
    blocks = text.to_s.split(/\n{2,}/).map(&:strip).reject(&:blank?)
    safe_join(blocks.map do |block|
      if block.length <= 32 && block.end_with?(":")
        content_tag(:p, block, class: "desc-heading")
      else
        content_tag(:p, block)
      end
    end)
  end

  # Marks the current top-nav item as active.
  def nav_active?(path)
    current_page?(path) ? "is-active" : nil
  end

  def page_title(title = nil)
    base = "Nexus Shine — професионална почистваща химия"
    title.present? ? "#{title} · Nexus Shine" : base
  end
end
