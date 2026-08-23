module AdminHelper
  def admin_low_stock_count
    @admin_low_stock_count ||= Product.active.low_stock.count
  end

  # Marks the active sidebar link based on the current admin controller.
  def admin_nav_class(key)
    active = controller_name == key
    ["admin-nav-link", ("is-active" if active)].compact.join(" ")
  end

  ORDER_STATUS_LABELS = {
    "pending"   => "Нова",
    "confirmed" => "Потвърдена",
    "shipped"   => "Изпратена",
    "delivered" => "Доставена",
    "cancelled" => "Отказана",
  }.freeze

  def order_status_label(status)
    ORDER_STATUS_LABELS[status] || status
  end

  def order_status_badge(status)
    content_tag(:span, order_status_label(status), class: "status-badge status-#{status}")
  end

  PAYMENT_STATUS_LABELS = { "pending" => "Очаква", "paid" => "Платена", "failed" => "Неуспешна" }.freeze

  def payment_method_label(method)
    Order::PAYMENT_METHOD_LABELS[method] || method
  end

  def payment_status_label(status)
    PAYMENT_STATUS_LABELS[status] || status
  end

  def payment_status_badge(status)
    content_tag(:span, payment_status_label(status), class: "status-badge pay-#{status}")
  end
end
