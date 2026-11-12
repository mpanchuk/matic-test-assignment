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

  # [rule, discount in dollars] for each rule that applies, in the order given.
  def discounts
    basket = snapshot
    @rules.filter_map do |rule|
      cents = rule.discount(basket)
      [rule, dollars(cents)] unless cents.zero?
    end
  end

  def total
    basket = snapshot
    dollars(basket.subtotal - @rules.sum { |rule| rule.discount(basket) })
  end

  private

  def snapshot
    Basket.new(@codes, @catalog)
  end

  def dollars(cents)
    cents / 100.0
  end
end
