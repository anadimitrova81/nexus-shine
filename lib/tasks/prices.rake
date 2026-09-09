namespace :products do
  # Supplier price list, September 2026 — "Total Price" column, in EUR cents.
  PRICE_LIST_2026_09 = {
    "auto-foam"                    => 4400,  # WAXED AUTO SHAMPOO 0,5/60 CONCENTRATE 20KG
    "auto-shampoo"                 => 4700,  # AUTO SHAMPOO 0,5/60 HIGH CONCENTRATE 20KG
    "tire"                         => 4800,  # Turbopax Tire Shine 5 Kg
    "eengine-and-rim"              => 1700,  # Turbopax Auto Engine and Rim Cleaner 5 Kg
    "turbopax-torpedo"             => 4100,  # TORPEDO FRONT FACE POLISHER
    "turbopax-auto-detail-cleaner" => 4800,  # AUTO DETAIL CLEANER
    "turbopax-polish-gel"          => 3200,  # AUTO PRATICAL POLISH SPRAY APPLYING
    "carpet-shampoo"               => 16000, # Era 111 Super Naturemax 30 Lt
    "stain-remover"                => 11000, # Era 111 A Type Plus 20 Lt
    "parfume-my-todays"            => 10500, # Era 111 My Todays 20 Lt
    "multi-ekinoze"                => 15500, # Era 111 Multi Ekinoze 20 Lt
    "power-1-modified-spray"       => 750,   # Power 1 Modified Spray 1L
  }.freeze

  desc "Apply the September 2026 supplier price list (Total Price column) to products"
  task apply_price_list: :environment do
    PRICE_LIST_2026_09.each do |slug, cents|
      product = Product.find_by(slug: slug)
      next puts("MISSING #{slug}") unless product
      old = product.price_cents
      product.update!(price_cents: cents) if old != cents
      puts format("%-30s %8.2f -> %8.2f %s", slug, old / 100.0, cents / 100.0, old == cents ? "(unchanged)" : "")
    end
  end
end
