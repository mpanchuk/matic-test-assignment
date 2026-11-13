# frozen_string_literal: true

require_relative 'basket'
require_relative 'product'

# Scans product codes and totals the basket. Each rule returns a discount in
# integer cents for the basket, and the discounts add up. The public money
# methods return Float dollars, converted once from cents.
class Checkout
  class UnknownProductError < StandardError; end
  class InvalidDiscountError < StandardError; end

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
      cents = discount_cents(rule, basket)
      [rule, dollars(cents)] unless cents.zero?
    end
  end

  # Never below zero, even when offers that stack on the same units discount
  # more than the subtotal.
  def total
    basket = snapshot
    dollars([basket.subtotal - @rules.sum { |rule| discount_cents(rule, basket) }, 0].max)
  end

  private

  def snapshot
    Basket.new(@codes, @catalog)
  end

  def discount_cents(rule, basket)
    cents = rule.discount(basket)
    return cents if cents.is_a?(Integer) && !cents.negative?

    raise InvalidDiscountError, "#{rule} returned #{cents.inspect}, not a non-negative Integer of cents"
  end

  def dollars(cents)
    cents / 100.0
  end
end
