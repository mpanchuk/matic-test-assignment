# frozen_string_literal: true

require 'open3'

RSpec.describe 'bin/checkout' do
  let(:script) { File.expand_path('../../bin/checkout', __dir__) }

  def run_checkout(input)
    Open3.capture3(RbConfig.ruby, script, stdin_data: input)
  end

  it 'lists the products with their prices' do
    stdout, = run_checkout('')

    expect(stdout).to include('FR Fruit Tea $3.11', 'SR Strawberries $5.00', 'CF Coffee $11.23', 'AJ Apple Juice $7.25')
  end

  it 'prints the subtotal, each offer that applied and the total after every scan' do
    stdout, = run_checkout("FR\nSR\nFR\nFR\nCF\n")
    last_scan = stdout.split("\n\n").last

    expect(stdout.scan(/^\s+Total\s/).size).to eq(5)
    expect(last_scan).to match(/^CF Coffee$/)
      .and match(/^\s+Subtotal\s+\$25\.56$/)
      .and match(/^\s+FR: buy one, get one free\s+-\$3\.11$/)
      .and match(/^\s+Total\s+\$22\.45$/)
  end

  it 'applies the bulk price for strawberries' do
    stdout, = run_checkout("SR\nSR\nSR\n")

    expect(stdout.split("\n\n").last)
      .to match(/^\s+SR: bulk price for 3 or more\s+-\$1\.50$/)
      .and match(/^\s+Total\s+\$13\.50$/)
  end

  it 'accepts lowercase codes and surrounding whitespace' do
    stdout, = run_checkout(" fr \nFr\n")

    expect(stdout.split("\n\n").last).to match(/^\s+Total\s+\$3\.11$/)
  end

  it 'reports an unknown code and carries on' do
    stdout, stderr, status = run_checkout("XX\nFR\n")

    expect(stderr).to include('Unknown product code: "XX"')
    expect(stdout.split("\n\n").last).to match(/^\s+Total\s+\$3\.11$/)
    expect(status).to be_success
  end

  it 'reports an unknown code in sequence with the scans when output is redirected' do
    output, = Open3.capture2e(RbConfig.ruby, script, stdin_data: "FR\nXX\n")

    expect(output.index('Unknown product code')).to be > output.index('Total')
  end
end
