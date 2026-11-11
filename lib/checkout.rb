# frozen_string_literal: true

require_relative 'product'

# Scans product codes and totals the basket in integer cents.
class Checkout
  class UnknownProductError < StandardError; end

  def initialize(catalog: CATALOG)
    @catalog = catalog
    @codes = []
  end

  def scan(code)
    raise UnknownProductError, "Unknown product code: #{code.inspect}" unless @catalog.key?(code)

    @codes << code
    nil
  end

  def total
    @codes.sum { |code| @catalog.fetch(code).price }
  end
end
