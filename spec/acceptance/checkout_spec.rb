# frozen_string_literal: true

require 'checkout'
require 'rules/buy_one_get_one_free'
require 'rules/bulk_price'

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
end
