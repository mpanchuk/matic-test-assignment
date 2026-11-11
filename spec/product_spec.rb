# frozen_string_literal: true

require 'product'

RSpec.describe 'CATALOG' do
  it 'holds the four products, keyed by code, priced in cents' do
    expect(CATALOG).to eq(
      'FR' => Product.new(code: 'FR', name: 'Fruit Tea', price: 311),
      'SR' => Product.new(code: 'SR', name: 'Strawberries', price: 500),
      'CF' => Product.new(code: 'CF', name: 'Coffee', price: 1123),
      'AJ' => Product.new(code: 'AJ', name: 'Apple Juice', price: 725)
    )
  end

  it 'is frozen' do
    expect(CATALOG).to be_frozen
  end
end
