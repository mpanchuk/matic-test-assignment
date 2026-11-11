# frozen_string_literal: true

# A product's price is in integer cents.
Product = Data.define(:code, :name, :price)

CATALOG = [
  Product.new(code: 'FR', name: 'Fruit Tea', price: 311),
  Product.new(code: 'SR', name: 'Strawberries', price: 500),
  Product.new(code: 'CF', name: 'Coffee', price: 1123),
  Product.new(code: 'AJ', name: 'Apple Juice', price: 725)
].to_h { |product| [product.code, product] }.freeze
