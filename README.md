# Matic Test Assignment

Task 1 is a grocery checkout with pricing rules, in plain Ruby with no runtime gems. The
requirements are in [`docs/assignment.md`](docs/assignment.md). The design decisions and the
reasons for them are in [`docs/decisions.md`](docs/decisions.md).

## Setup

Ruby 3.3 (see `.ruby-version`). RSpec and RuboCop are development dependencies only.

```sh
bundle install
bundle exec rspec
bundle exec rubocop
```

## Usage

```ruby
require_relative 'lib/checkout'
require_relative 'lib/rules/buy_one_get_one_free'
require_relative 'lib/rules/bulk_price'

co = Checkout.new(
  Rules::BuyOneGetOneFree.new('FR'),
  Rules::BulkPrice.new('SR', min_quantity: 3, price: 450)
)
%w[FR SR FR FR CF].each { |code| co.scan(code) }

co.total     # => 22.45
co.subtotal  # => 25.56
co.discounts # => [[#<Rules::BuyOneGetOneFree ...>, 3.11]]
co.discounts.map { |rule, amount| [rule.to_s, amount] }
# => [["FR: buy one, get one free", 3.11]]
```

- `total`, `subtotal` and `discounts` return Float dollars, so `co.total == 22.45` is true.
  Inside, prices and discounts are integer cents, and `Checkout` converts once, at the end.
- Prices come from `CATALOG` in `lib/product.rb`. Pass `catalog:` to use other products.
- Scanning a code that isn't in the catalog raises `Checkout::UnknownProductError` and leaves
  the basket unchanged.

### Interactive checkout

`bin/checkout` runs a checkout with the current offers. Type one product code per line, in
any case, and press Ctrl-D to finish. After each scan it prints the subtotal, each offer that
applied, and the total:

```
$ printf 'FR\nSR\nFR\nFR\nCF\n' | bin/checkout
...
CF Coffee
  Subtotal                          $25.56
  FR: buy one, get one free         -$3.11
  Total                             $22.45
```

An unknown code prints an error and the session carries on.

## Adding a rule

A rule is any object with two methods:

- `discount(basket)` returns the discount in integer cents, never negative.
- `to_s` returns a label for the breakdown.

The basket is a frozen snapshot with `count(code)`, `unit_price(code)` and `subtotal`. Every
rule sees the same basket and the discounts add up, so the order of rules doesn't matter.
Offers that overlap on the same unit stack, and the total never goes below zero; decision 8
explains why and when to change that.

To add a rule:

1. Write its spec in `spec/rules/` and its class in `lib/rules/`.
2. Pass an instance to `Checkout.new`, and add it to `bin/checkout` if it is a live offer.

`Checkout` doesn't change. For example, $5 off orders of $50 or more:

```ruby
module Rules
  class AmountOffOver
    def initialize(threshold:, amount:)
      @threshold = threshold
      @amount = amount
    end

    def discount(basket)
      basket.subtotal >= @threshold ? @amount : 0
    end

    def to_s
      'Order discount'
    end
  end
end

Checkout.new(Rules::AmountOffOver.new(threshold: 5000, amount: 500))
```

`Rules::PercentOffWithPurchase` ("buy Fruit Tea, get 20% off Coffee") spans two products and
was added the same way, with no change to `Checkout`.

## Layout

```
lib/product.rb      Product and CATALOG
lib/basket.rb       the read-only snapshot rules see
lib/checkout.rb     scan, subtotal, discounts, total
lib/rules/          one class per rule
bin/checkout        interactive CLI
spec/acceptance/    the assignment examples
spec/               unit specs, mirroring lib/ and bin/
```
