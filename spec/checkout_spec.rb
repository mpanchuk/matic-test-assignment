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
      expect(checkout.total).to eq(0.0)
    end

    it 'sums the prices of the scanned products, in dollars' do
      %w[A B A].each { |code| checkout.scan(code) }

      expect(checkout.total).to eq(4.5)
    end

    it 'is a Float' do
      checkout.scan('A')

      expect(checkout.total).to be_a(Float)
    end

    it 'prices products from CATALOG by default' do
      default_checkout = described_class.new
      default_checkout.scan('FR')

      expect(default_checkout.total).to eq(3.11)
    end

    it "subtracts every rule's discount, given in cents, from the subtotal" do
      rules = [double(:rule, discount: 30), double(:rule, discount: 20)]
      with_rules = described_class.new(*rules, catalog:)
      %w[A B A].each { |code| with_rules.scan(code) }

      expect(with_rules.total).to eq(4.0)
    end

    it 'counts a rule passed twice, twice' do
      rule = double(:rule, discount: 30)
      with_rules = described_class.new(rule, rule, catalog:)
      %w[A B].each { |code| with_rules.scan(code) }

      expect(with_rules.total).to eq(2.9)
    end

    it 'never goes below zero when the discounts exceed the subtotal' do
      with_rules = described_class.new(double(:rule, discount: 300), double(:rule, discount: 200), catalog:)
      %w[A B].each { |code| with_rules.scan(code) }

      expect(with_rules.total).to eq(0.0)
    end

    it 'gives each rule a basket of the scanned products' do
      ten_off_each_a = double(:rule)
      allow(ten_off_each_a).to receive(:discount) { |basket| basket.count('A') * 10 }
      with_rule = described_class.new(ten_off_each_a, catalog:)
      %w[A B A].each { |code| with_rule.scan(code) }

      expect(with_rule.total).to eq(4.3)
    end
  end

  describe '#subtotal' do
    it 'sums the prices before any discount, in dollars' do
      with_rule = described_class.new(double(:rule, discount: 30), catalog:)
      %w[A B].each { |code| with_rule.scan(code) }

      expect(with_rule.subtotal).to eq(3.5)
    end
  end

  describe '#discounts' do
    it 'pairs each rule that applies with its discount in dollars' do
      applies = double(:rule, discount: 30)
      does_not_apply = double(:rule, discount: 0)
      also_applies = double(:rule, discount: 20)
      with_rules = described_class.new(applies, does_not_apply, also_applies, catalog:)

      expect(with_rules.discounts).to eq([[applies, 0.3], [also_applies, 0.2]])
    end

    it 'lists a rule passed twice, twice' do
      rule = double(:rule, discount: 30)

      expect(described_class.new(rule, rule, catalog:).discounts).to eq([[rule, 0.3], [rule, 0.3]])
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
      expect(checkout.total).to eq(1.0)
    end
  end
end
