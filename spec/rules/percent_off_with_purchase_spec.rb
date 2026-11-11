# frozen_string_literal: true

require 'basket'
require 'product'
require 'rules/percent_off_with_purchase'

RSpec.describe Rules::PercentOffWithPurchase do
  subject(:rule) { described_class.new(trigger: 'A', target: 'B', percent: 20) }

  let(:catalog) do
    {
      'A' => Product.new(code: 'A', name: 'Apple', price: 100),
      'B' => Product.new(code: 'B', name: 'Banana', price: 250),
      'C' => Product.new(code: 'C', name: 'Cherry', price: 105)
    }
  end

  {
    [] => 0,
    %w[A] => 0,
    %w[B] => 0,
    %w[A B] => 50,
    %w[B A] => 50,
    %w[A A B] => 50,
    %w[A B B] => 50,
    %w[A A B B] => 100,
    %w[A C] => 0
  }.each do |codes, expected_discount|
    it "discounts #{codes.inspect} by #{expected_discount} cents" do
      expect(rule.discount(Basket.new(codes, catalog))).to eq(expected_discount)
    end
  end

  it 'rounds the discount per unit, half away from zero' do
    ten_percent_off_c = described_class.new(trigger: 'A', target: 'C', percent: 10)

    # 10% of 105 is 10.5, rounded to 11 per unit; rounding the total would give 21.
    expect(ten_percent_off_c.discount(Basket.new(%w[A A C C], catalog))).to eq(22)
  end
end
