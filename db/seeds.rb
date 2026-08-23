# Seed data for the Nexus Shine shop. Idempotent: keyed on slug, so re-running
# updates existing records rather than duplicating them.

BRANDS = {
  "era-111"  => { name: "ERA 111 Professional", description: "Професионални препарати за дълбоко пране на килими, използвани основно в перални за килими. Висока концентрация и безопасност за материите и оборудването." },
  "turbopax" => { name: "TURBOPAX", description: "Иновативни почистващи и защитни продукти за автомобили и индустрия с акцент върху защитата на повърхностите." },
  "power-1"  => { name: "Power 1", description: "Многофункционална химия за автомобили, дома и индустрията." },
}

brand = {}
BRANDS.each do |slug, attrs|
  brand[slug] = Brand.find_or_initialize_by(slug: slug).tap { |b| b.update!(attrs) }
end

CATEGORIES = {
  "carwash"         => { name: "Автомивки", position: 1, description: "Професионални препарати за самообслужващи се автомивки – активни пени, шампоани, вакси и препарати за гуми и джанти." },
  "carpet-washing"  => { name: "Пране на килими", position: 2, description: "Висококонцентрирани шампоани, препарати за петна и парфюми за професионални перални за килими." },
  "other"           => { name: "Други", position: 3, description: "Многофункционални почистващи препарати за дома, работилницата и индустрията." },
}

category = {}
CATEGORIES.each do |slug, attrs|
  category[slug] = Category.find_or_initialize_by(slug: slug).tap { |c| c.update!(attrs) }
end

PRODUCTS = [
  {
    slug: "auto-foam", name: "TURBOPAX – Активна пяна с восък 20 кг", brand: "turbopax",
    price_cents: 4670, size: "20 кг", categories: %w[carwash], featured: true,
    short_description: "Професионален безконтактен шампоан с восък за автомивки.",
    description: "Професионален безконтактен автошампоан, който съчетава силни почистващи агенти с качествени восъчни компоненти. Формулата разгражда упоритата мръсотия, прах, омазнявания и следи от насекоми. Оставя блестящ защитен слой с антистатичен ефект, който отблъсква праха, предпазва боята от UV лъчи и атмосферни влияния и улеснява изплакването без остатък.\n\nКонцентрация: 1 кг продукт на 120 литра вода. Подходящ за пенообразуващи системи и водоструйки.",
  },
  {
    slug: "auto-shampoo", name: "TURBOPAX – Високо концентриран авто-шампоан 20 кг", brand: "turbopax",
    price_cents: 5130, size: "20 кг", categories: %w[carwash],
    short_description: "Икономичен високо концентриран шампоан за автомивки.",
    description: "Високо концентриран автошампоан за професионални и самообслужващи се автомивки. Образува гъста стабилна пяна, която обгръща повърхността и разгражда замърсяванията бързо и ефективно, като се изплаква лесно без следи.",
  },
  {
    slug: "tire", name: "TURBOPAX – Блясък за гуми 5 кг", brand: "turbopax",
    price_cents: 1780, size: "5 кг", categories: %w[carwash], best_seller: true,
    short_description: "Придава дълготраен черен блясък на гумите.",
    description: "Препарат за придаване на дълбок черен блясък на външните гуми. Освежава и предпазва каучука, като оставя равномерно матово-гланцово покритие без омазняване.",
  },
  {
    slug: "eengine-and-rim", name: "TURBOPAX – За двигатели и джанти 5 кг", brand: "turbopax",
    price_cents: 1780, size: "5 кг", categories: %w[carwash],
    short_description: "Мощен обезмаслител за двигатели и джанти.",
    description: "Силен алкален препарат за почистване на двигатели, джанти и силно замърсени метални и пластмасови части. Разтваря масла, катран и спирачен прах бързо и без агресивно търкане.",
  },
  {
    slug: "turbopax-torpedo", name: "TURBOPAX – Torpedo препарат за интериор 5 кг", brand: "turbopax",
    price_cents: 1780, size: "5 кг", categories: %w[carwash], best_seller: true,
    short_description: "Освежава и защитава пластмасите в интериора.",
    description: "Препарат за почистване и защита на арматурното табло и пластмасовите повърхности в интериора. Оставя копринено-матов финиш с антистатичен ефект и приятен аромат.",
  },
  {
    slug: "turbopax-auto-detail-cleaner", name: "TURBOPAX – Auto Detail Cleaner 5 кг", brand: "turbopax",
    price_cents: 1780, size: "5 кг", categories: %w[carwash],
    short_description: "Универсален препарат за детайлно почистване.",
    description: "Универсален детайлинг препарат за интериор и екстериор. Отстранява упорити замърсявания от текстил, пластмаса и винил, без да уврежда повърхностите.",
  },
  {
    slug: "turbopax-polish-gel", name: "TURBOPAX – Авто вакса 5 кг", brand: "turbopax",
    price_cents: 2330, size: "5 кг", categories: %w[carwash], best_seller: true,
    short_description: "Течна вакса за блясък и защита на боята.",
    description: "Течна вакса за бързо нанасяне при автомивки. Придава наситен блясък и хидрофобен защитен слой, който отблъсква водата и предпазва боята от атмосферни влияния.",
  },
  {
    slug: "carpet-shampoo", name: "ERA 111 Super Naturemax – Шампоан за килими", brand: "era-111",
    price_cents: 16000, size: "30 кг", categories: %w[carpet-washing], featured: true,
    short_description: "Високо концентриран шампоан за машинно и ръчно пране на килими.",
    description: "Високо концентриран професионален шампоан за машинно или ръчно пране на килими. Формулата прониква дълбоко във влакната и премахва упоритите замърсявания, петна и миризми, като запазва мекотата и свежестта на цветовете. Неутралното pH го прави безопасен за вълна и деликатни материи.\n\nПредимства: гъста стабилна пяна, без лепкав остатък, икономичен разход (30 кг за до 5500 м²), антистатичен и антиалергичен ефект, приятен свеж аромат.\n\nРазреждане 3:1000 (3 кг шампоан на 1000 л вода).",
  },
  {
    slug: "stain-remover", name: "ERA 111 A Type Plus – Препарат за петна", brand: "era-111",
    price_cents: 13500, size: "20 кг", categories: %w[carpet-washing], featured: true,
    short_description: "Мощен препарат за премахване на упорити петна.",
    description: "Професионален препарат за предварителна обработка и премахване на упорити петна от килими и текстил. Разгражда органични и мазни замърсявания, без да уврежда влакната и цветовете.",
  },
  {
    slug: "parfume-my-todays", name: "ERA 111 My Todays – Парфюм за килими", brand: "era-111",
    price_cents: 14200, size: "20 кг", categories: %w[carpet-washing], featured: true,
    short_description: "Концентриран парфюм за дълготрайна свежест.",
    description: "Концентриран парфюм за килими, който придава дълготраен свеж аромат след пране. Добавя се към водата за изплакване и оставя приятно ухание, без да оставя следи.",
  },
  {
    slug: "multi-ekinoze", name: "ERA 111 Multi Ekinoze – Парфюм за килими", brand: "era-111",
    price_cents: 19500, size: "20 кг", categories: %w[carpet-washing], best_seller: true,
    short_description: "Премиум многофункционален парфюм за килими.",
    description: "Премиум концентриран парфюм за килими с богат, устойчив аромат. Подходящ за професионални перални за килими, където се търси дълготрайна свежест.",
  },
  {
    slug: "power-1-modified-spray", name: "Power 1 Modified Spray – Многофункционален почистващ спрей (1 L)", brand: "power-1",
    price_cents: 520, size: "1 L", categories: %w[carwash other carpet-washing], best_seller: true,
    short_description: "Многофункционален спрей срещу масла, катран и упорити петна.",
    description: "Многофункционален почистващ спрей, който ефективно премахва масла, мазнини, катран, лепила и упорити петна от различни повърхности – метал, пластмаса и текстил. Формулиран с над 10 вида разтворители като по-безопасна алтернатива на агресивни химикали.\n\nПриложение: двигатели, джанти, метални и пластмасови части, кухненски уреди, текстил, тапицерии, килими, пердета, мебели и силно замърсени индустриални зони.\n\nУпотреба: разклатете добре, напръскайте директно върху замърсената повърхност, изчакайте 1–2 минути, при нужда разтъркайте и изплакнете или избършете с влажна кърпа.",
  },
]

PRODUCTS.each_with_index do |attrs, index|
  cats = attrs.delete(:categories)
  brand_slug = attrs.delete(:brand)
  product = Product.find_or_initialize_by(slug: attrs[:slug])
  product.assign_attributes(attrs.merge(brand: brand[brand_slug], position: index + 1, active: true))
  product.save!
  product.categories = cats.map { |c| category[c] }
end

# Product weights (kg) used for Speedy shipping calculation.
WEIGHTS_KG = {
  "auto-foam" => 20, "auto-shampoo" => 20, "tire" => 5, "eengine-and-rim" => 5,
  "turbopax-torpedo" => 5, "turbopax-auto-detail-cleaner" => 5, "turbopax-polish-gel" => 5,
  "carpet-shampoo" => 30, "stain-remover" => 20, "parfume-my-todays" => 20,
  "multi-ekinoze" => 20, "power-1-modified-spray" => 1,
}.freeze
WEIGHTS_KG.each { |slug, kg| Product.where(slug: slug).update_all(weight_grams: (kg * 1000).to_i) }

# Starting stock for development/demo.
Product.where(stock_quantity: 0).update_all(stock_quantity: 100)

# Full descriptions and "Допълнителна информация" scraped from nexus-shine.com,
# keyed by slug. Optional: seeds still work without the file.
content_path = Rails.root.join("db/seeds/product_content.json")
if File.exist?(content_path)
  JSON.parse(File.read(content_path)).each do |row|
    product = Product.find_by(slug: row["slug"])
    next unless product
    product.description = row["description"] if row["description"].present?
    product.specs = row["specs"] if row["specs"].present?
    product.save!
  end
  puts "Applied scraped Описание/Допълнителна информация for #{Product.where.not(specs: []).count} products."
end

puts "Seeded #{Brand.count} brands, #{Category.count} categories, #{Product.count} products."
