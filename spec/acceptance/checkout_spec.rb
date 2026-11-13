# frozen_string_literal: true

require 'checkout'
require 'rules/buy_one_get_one_free'
require 'rules/bulk_price'
require 'rules/percent_off_with_purchase'

RSpec.describe 'Checkout with the current offers' do
  subject(:checkout) { Checkout.new(*rules) }

  let(:rules) do
    [
      Rules::BuyOneGetOneFree.new('FR'),
      Rules::BulkPrice.new('SR', min_quantity: 3, price: 450)
    ]
  end

  {
    %w[FR SR FR FR CF] => 22.45,
    %w[FR FR] => 3.11,
    %w[SR SR FR SR] => 16.61
  }.each do |items, expected_total|
    it "totals #{items.join(', ')} to $#{expected_total}" do
      items.each { |code| checkout.scan(code) }

      expect(checkout.total).to eq(expected_total)
    end
  end

  context 'with the invented cross-product offer: 20% off one Coffee per Fruit Tea' do
    let(:rules) do
      [
        Rules::BuyOneGetOneFree.new('FR'),
        Rules::BulkPrice.new('SR', min_quantity: 3, price: 450),
        Rules::PercentOffWithPurchase.new(trigger: 'FR', target: 'CF', percent: 20)
      ]
    end

    {
      %w[FR CF] => 12.09,
      %w[FR FR CF CF] => 21.07
    }.each do |items, expected_total|
      it "totals #{items.join(', ')} to $#{expected_total}" do
        items.each { |code| checkout.scan(code) }

        expect(checkout.total).to eq(expected_total)
      end
    end

    it 'totals the same whatever the order of the rules' do
      reversed = Checkout.new(*rules.reverse)
      %w[FR FR CF CF SR SR SR].each do |code|
        checkout.scan(code)
        reversed.scan(code)
      end

      expect(reversed.total).to eq(checkout.total)
    end
  end
end
