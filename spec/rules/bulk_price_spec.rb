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
end
