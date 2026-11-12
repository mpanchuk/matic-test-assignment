# frozen_string_literal: true

# A frozen snapshot of the scanned codes, priced from a catalog. It is the
# only thing pricing rules see. Prices are integer cents. Asking about a code
# that is not in the catalog raises KeyError, so a misspelled rule code fails
# loudly instead of the rule never applying.
class Basket
  def initialize(codes, catalog)
    @counts = codes.tally.freeze
    @catalog = catalog
    freeze
  end

  def count(code)
    product(code)
    @counts.fetch(code, 0)
  end

  def unit_price(code)
    product(code).price
  end

  def subtotal
    @counts.sum { |code, quantity| quantity * unit_price(code) }
  end

  private

  def product(code)
    @catalog.fetch(code) { raise KeyError, "Unknown product code: #{code.inspect}" }
  end
end
