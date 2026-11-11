# frozen_string_literal: true

require 'basket'
require 'product'
require 'rules/buy_one_get_one_free'

RSpec.describe Rules::BuyOneGetOneFree do
  subject(:rule) { described_class.new('A') }

  let(:catalog) do
    {
      'A' => Product.new(code: 'A', name: 'Apple', price: 100),
      'B' => Product.new(code: 'B', name: 'Banana', price: 250)
    }
  end

  {
    [] => 0,
    %w[A] => 0,
    %w[A A] => 100,
    %w[A A A] => 100,
    %w[A B A] => 100,
    %w[A A A A] => 200,
    %w[B B] => 0
  }.each do |codes, expected_discount|
    it "discounts #{codes.inspect} by #{expected_discount} cents" do
      expect(rule.discount(Basket.new(codes, catalog))).to eq(expected_discount)
    end
  end
end
