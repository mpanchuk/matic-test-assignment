# frozen_string_literal: true

module Rules
  # Bulk price: buy at least min_quantity units and each one costs price
  # (integer cents) instead of the catalog price.
  class BulkPrice
    def initialize(code, min_quantity:, price:)
      @code = code
      @min_quantity = min_quantity
      @price = price
    end

    def discount(basket)
      quantity = basket.count(@code)
      return 0 if quantity < @min_quantity

      quantity * (basket.unit_price(@code) - @price)
    end
  end
end
