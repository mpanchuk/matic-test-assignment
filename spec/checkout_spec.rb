# frozen_string_literal: true

require 'checkout'

RSpec.describe Checkout do
  subject(:checkout) { described_class.new(catalog:) }

  let(:catalog) do
    {
      'A' => Product.new(code: 'A', name: 'Apple', price: 100),
      'B' => Product.new(code: 'B', name: 'Banana', price: 250)
    }
  end

  describe '#total' do
    it 'is zero when nothing is scanned' do
      expect(checkout.total).to eq(0)
    end

    it 'sums the prices of the scanned products' do
      %w[A B A].each { |code| checkout.scan(code) }

      expect(checkout.total).to eq(450)
    end

    it 'prices products from CATALOG by default' do
      default_checkout = described_class.new
      default_checkout.scan('FR')

      expect(default_checkout.total).to eq(CATALOG['FR'].price)
    end
  end

  describe '#scan' do
    it 'raises UnknownProductError for a code not in the catalog' do
      expect { checkout.scan('XX') }
        .to raise_error(Checkout::UnknownProductError, 'Unknown product code: "XX"')
    end

    it 'leaves the basket unchanged when the code is unknown' do
      checkout.scan('A')

      expect { checkout.scan('XX') }.to raise_error(Checkout::UnknownProductError)
      expect(checkout.total).to eq(100)
    end
  end
end
