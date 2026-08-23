# A session-backed shopping cart. Not an Active Record model: the cart lives in
# the session as a { product_id => quantity } hash and only turns into a
# persisted Order at checkout. Wrapping it in a class keeps the controllers thin
# and gives the views a tidy API (totals, item count, iteration).
class Cart
  include Enumerable

  MAX_QUANTITY = 99

  def initialize(session)
    @session = session
    @session[:cart] ||= {}
  end

  def store
    @session[:cart]
  end

  def add(product, quantity = 1)
    id = product.id.to_s
    new_quantity = (store[id].to_i + quantity.to_i).clamp(1, MAX_QUANTITY)
    store[id] = new_quantity
  end

  def set(product, quantity)
    id = product.id.to_s
    quantity = quantity.to_i
    if quantity <= 0
      remove(product)
    else
      store[id] = quantity.clamp(1, MAX_QUANTITY)
    end
  end

  def remove(product)
    store.delete(product.id.to_s)
  end

  def clear
    @session[:cart] = {}
  end

  # Yields [product, quantity] for each line, skipping products that no longer
  # exist. Loads all products in one query and preserves insertion order.
  def each(&block)
    return enum_for(:each) unless block_given?
    products_by_id.each do |id, product|
      yield product, store[id]
    end
  end

  def empty?
    products_by_id.empty?
  end

  def item_count
    products_by_id.keys.sum { |id| store[id] }
  end

  def total_cents
    products_by_id.sum { |id, product| product.price_cents * store[id] }
  end

  # Total cart weight in kilograms, for Speedy shipping calculation.
  def total_weight_kg
    grams = products_by_id.sum { |id, product| product.weight_grams.to_i * store[id] }
    (grams / 1000.0).round(3)
  end

  def total
    Money.new(total_cents)
  end

  private

  def products_by_id
    ids = store.keys
    return {} if ids.empty?
    found = Product.where(id: ids).index_by { |p| p.id.to_s }
    # Preserve the order items were added in, dropping any stale ids.
    ids.filter_map { |id| [id, found[id]] if found[id] }.to_h
  end
end
