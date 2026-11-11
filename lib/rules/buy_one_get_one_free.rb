# frozen_string_literal: true

module Rules
  # Buy one, get one free: every second unit of the product is free.
  class BuyOneGetOneFree
    def initialize(code)
      @code = code
    end

    def discount(basket)
      basket.count(@code) / 2 * basket.unit_price(@code)
    end
  end
end
