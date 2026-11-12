# frozen_string_literal: true

require 'basket'
require 'product'
require 'rules/bulk_price'

RSpec.describe Rules::BulkPrice do
  subject(:rule) { described_class.new('A', min_quantity: 3, price: 80) }

  let(:catalog) do
    {
      'A' => Product.new(code: 'A', name: 'Apple', price: 100),
      'B' => Product.new(code: 'B', name: 'Banana', price: 250)
    }
  end

  {
    [] => 0,
    %w[A A] => 0,
    %w[A A A] => 60,
    %w[A B A B A] => 60,
    %w[A A A A] => 80,
    %w[B B B] => 0
  }.each do |codes, expected_discount|
    it "discounts #{codes.inspect} by #{expected_discount} cents" do
      expect(rule.discount(Basket.new(codes, catalog))).to eq(expected_discount)
    end
  end

  it 'gives no discount when the bulk price is not below the catalog price' do
    pricier = described_class.new('A', min_quantity: 3, price: 120)

    expect(pricier.discount(Basket.new(%w[A A A], catalog))).to eq(0)
  end

  it 'raises when its code is not in the catalog, instead of never applying' do
    misspelled = described_class.new('Z', min_quantity: 3, price: 80)

    expect { misspelled.discount(Basket.new(%w[A A A], catalog)) }.to raise_error(KeyError)
  end

  it 'is labelled with its product and offer' do
    expect(rule.to_s).to eq('A: bulk price for 3 or more')
  end

  describe 'arguments' do
    {
      { price: 4.5 } => 'price must be a non-negative Integer of cents, got 4.5',
      { price: -1 } => 'price must be a non-negative Integer of cents, got -1',
      { min_quantity: 0 } => 'min_quantity must be a positive Integer, got 0',
      { min_quantity: 2.5 } => 'min_quantity must be a positive Integer, got 2.5'
    }.each do |bad, message|
      it "rejects #{bad}" do
        expect { described_class.new('A', min_quantity: 3, price: 80, **bad) }
          .to raise_error(ArgumentError, message)
      end
    end

    it 'accepts a price of 0 and a min_quantity of 1' do
      expect { described_class.new('A', min_quantity: 1, price: 0) }.not_to raise_error
    end
  end
end
