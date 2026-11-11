# frozen_string_literal: true

# A frozen snapshot of the scanned codes, priced from a catalog. It is the
# only thing pricing rules see. Prices are integer cents.
class Basket
  def initialize(codes, catalog)
    @counts = codes.tally.freeze
    @catalog = catalog
    freeze
  end

  def count(code)
    @counts.fetch(code, 0)
  end

  def unit_price(code)
    @catalog.fetch(code).price
  end

  def subtotal
    @counts.sum { |code, quantity| quantity * unit_price(code) }
  end
end
