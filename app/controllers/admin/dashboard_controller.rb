module Admin
  class DashboardController < BaseController
    PERIODS = %w[today 7d 30d month year all custom].freeze

    def show
      @period = params[:period].presence_in(PERIODS) || "month"
      @range = resolve_range(@period)
      @from = @range&.begin&.to_date
      @to = @range&.end&.to_date

      scope = Order.all
      scope = scope.where(created_at: @range) if @range
      billable = scope.where.not(status: "cancelled")

      @status_counts = scope.group(:status).count
      @orders_count = scope.count
      @billable_count = billable.count
      total = billable.sum(:total_cents)
      @revenue = Money.new(total)
      @avg_order = Money.new(@billable_count.zero? ? 0 : (total / @billable_count))

      # Pending is actionable regardless of the reporting window.
      @pending_count = Order.where(status: "pending").count

      @products_count = Product.count
      @active_products = Product.active.count
      @categories_count = Category.count

      top = OrderItem.joins(:order).where.not(orders: { status: "cancelled" })
      top = top.where(orders: { created_at: @range }) if @range
      @top_products = top.group(:product_name)
        .order(Arel.sql("SUM(quantity) DESC"))
        .limit(5)
        .pluck(Arel.sql("product_name, SUM(quantity), SUM(unit_price_cents * quantity)"))

      @recent_orders = Order.order(created_at: :desc).limit(8)

      @low_stock_products = Product.active.low_stock.order(:stock_quantity).includes(:brand)
      @low_stock_count = @low_stock_products.size
    end

    private

    # Returns a Time range for the selected period, or nil for "all time".
    def resolve_range(period)
      today = Date.current
      case period
      when "today" then today.all_day
      when "7d"    then (today - 6.days).beginning_of_day..today.end_of_day
      when "30d"   then (today - 29.days).beginning_of_day..today.end_of_day
      when "year"  then today.beginning_of_year..today.end_of_day
      when "all"   then nil
      when "custom"
        from = parse_date(params[:from]) || today.beginning_of_month
        to   = parse_date(params[:to]) || today
        from.beginning_of_day..to.end_of_day
      else # "month"
        today.beginning_of_month..today.end_of_day
      end
    end

    def parse_date(value)
      Date.parse(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end
  end
end
