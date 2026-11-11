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

  def subtotal
    snapshot.subtotal
  end

  # Each rule that applies, mapped to its discount in cents.
  def discounts
    basket = snapshot
    @rules.to_h { |rule| [rule, rule.discount(basket)] }.reject { |_rule, cents| cents.zero? }
  end

  def total
    subtotal - discounts.values.sum
  end

  private

  def snapshot
    Basket.new(@codes, @catalog)
  end
end
