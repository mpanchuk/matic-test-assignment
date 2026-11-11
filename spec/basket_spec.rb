# frozen_string_literal: true

require 'basket'
require 'product'

RSpec.describe Basket do
  subject(:basket) { described_class.new(%w[A B A], catalog) }

  let(:catalog) do
    {
      'A' => Product.new(code: 'A', name: 'Apple', price: 100),
      'B' => Product.new(code: 'B', name: 'Banana', price: 250),
      'C' => Product.new(code: 'C', name: 'Cherry', price: 75)
    }
  end

  it 'counts the units of each product, zero if none were scanned' do
    expect(%w[A B C].map { |code| basket.count(code) }).to eq([2, 1, 0])
  end

  it 'prices a unit from the catalog' do
    expect(basket.unit_price('B')).to eq(250)
  end

  it 'totals the undiscounted prices' do
    expect(basket.subtotal).to eq(450)
  end

  it 'is frozen' do
    expect(basket).to be_frozen
  end

  it 'is a snapshot: later changes to the codes do not affect it' do
    codes = %w[A]
    snapshot = described_class.new(codes, catalog)
    codes << 'A'

    expect(snapshot.count('A')).to eq(1)
  end
end
