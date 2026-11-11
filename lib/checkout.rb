# frozen_string_literal: true

require_relative 'basket'
require_relative 'product'

# Scans product codes and totals the basket in integer cents. Each rule
# returns a discount for the basket, and the discounts add up.
class Checkout
  class UnknownProductError < StandardError; end

  def initialize(*rules, catalog: CATALOG)
    @rules = rules
    @catalog = catalog
    @codes = []
  end

  def scan(code)
    raise UnknownProductError, "Unknown product code: #{code.inspect}" unless @catalog.key?(code)

    @codes << code
    nil
  end

  def total
    basket = Basket.new(@codes, @catalog)
    basket.subtotal - @rules.sum { |rule| rule.discount(basket) }
  end
end
