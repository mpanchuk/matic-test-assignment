# frozen_string_literal: true

require 'product'

RSpec.describe 'CATALOG' do
  it 'keys each of the four products by its own code' do
    expect(CATALOG.transform_values(&:code)).to eq('FR' => 'FR', 'SR' => 'SR', 'CF' => 'CF', 'AJ' => 'AJ')
  end

  it 'prices every product in Integer cents' do
    expect(CATALOG.values.map(&:price)).to all(be_a(Integer))
  end
end
