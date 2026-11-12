# frozen_string_literal: true

require_relative 'basket'
require_relative 'product'

# Scans product codes and totals the basket. Each rule returns a discount in
# integer cents for the basket, and the discounts add up. The public money
# methods return Float dollars, converted once from cents.
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
    dollars(snapshot.subtotal)
  end

  # Each rule that applies, mapped to its discount in dollars.
  def discounts
    discount_cents(snapshot).transform_values { |cents| dollars(cents) }
  end

  def total
    basket = snapshot
    dollars(basket.subtotal - discount_cents(basket).values.sum)
  end

  private

  def snapshot
    Basket.new(@codes, @catalog)
  end

  def discount_cents(basket)
    @rules.to_h { |rule| [rule, rule.discount(basket)] }.reject { |_rule, cents| cents.zero? }
  end

  def dollars(cents)
    cents / 100.0
  end
end
