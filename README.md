# Matic Test Assignment

Two tasks from [`docs/assignment.md`](docs/assignment.md): a grocery checkout with pricing
rules (Task 1), and a spec, architecture and rollout plan for a link shortener (Task 2). The
questions I asked the team, and their answers, are in
[`docs/clarifications.md`](docs/clarifications.md).

## How I worked

**Task 1: checkout**

1. Asked the team whether a rule can span several products, and who adds new rules.
2. Compared three rule designs on the same basket and wrote down the decisions before any
   code ([`plan.md`](docs/plan.md), [`decisions.md`](docs/decisions.md)).
3. Turned the three example totals into acceptance specs.
4. Built it test first, one small commit per step, with RSpec and RuboCop green each time.
5. Had an AI review the code as a sceptical senior reviewer ([`review.md`](docs/review.md)),
   then fixed the High and Medium findings.

**Task 2: link shortener**

1. Asked the team eight questions: use case, who creates links, volume, sensitive data,
   tracking, interface, cost and constraints.
2. Wrote my own position on each topic first ([`notes.md`](docs/link-shortener/notes.md)).
3. Had an AI argue against each position
   ([`ai-arguments.md`](docs/link-shortener/ai-arguments.md)), then revised my notes.
4. Had an AI research vendor prices and the numbers for building
   ([`research.md`](docs/link-shortener/research.md)).
5. Wrote the plan for the team ([`docs/link-shortener/README.md`](docs/link-shortener/README.md)).

[`CLAUDE.md`](CLAUDE.md) holds the working rules I gave the AI assistant.

## Task 1: Discounts

Plain Ruby, no runtime gems. The interface is the one from the assignment:
`Checkout.new(rule1, rule2, ...)`, `scan(code)` and `total`, and `co.total == 22.45` for the
first example.

- A rule is any object with `discount(basket)`, which returns cents. The discounts add up, so
  the order of rules doesn't matter, and adding a rule never changes `Checkout`.
- Rules: buy one, get one free (Fruit Tea); bulk price (Strawberries); and an invented one,
  20% off one Coffee per Fruit Tea, to show that a rule over two products fits too.
- Money is integer cents inside and converted to dollars once, so sums stay exact.
- Overlapping offers stack, but the total never goes below zero. Offers that must not combine,
  or that depend on the amount after other offers, are out of scope (decisions 1 and 8).
- `bin/checkout` is the interactive interface: scan codes and see which offers applied.

## Task 2: Link shortener

The Call Center team asked what will be delivered and how much it will cost. The full plan is
in [`docs/link-shortener/README.md`](docs/link-shortener/README.md).

- **What:** a small service on a Matic-branded short domain. The SMS system sends a message's
  links in one call and puts the short links it gets back into the text. A link can expire,
  or be switched off at once. If the shortener is down, the SMS goes out with the long links.
- **Cost:** about 4 engineer-weeks to build (16–19 days, one engineer), then roughly low
  hundreds of dollars a month to run, plus an owner on call. Buying needs an enterprise
  contract at 1.5M links a month: from about $1,800 a year (Short.io, unconfirmed at this
  volume) to up to $22,500 a month (shortening built into the SMS provider).
- **Recommendation: build.** A short link can lead to a customer's policy documents, so we
  want control over the codes, how long links live and where the URLs are stored.
- **When:** 7–10 weeks: 3–4 to build, a 2-week pilot on one SMS template, then 2–4 to move
  the other templates. A feature flag switches back to long links at any point.
- **Needed from the team:** answers to 8 open questions, above all whether the destination
  pages ask the customer to log in.

The rest of this page is the Task 1 reference: setup, usage and how to add a rule.

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

- `discount(basket)` returns the discount in integer cents, never negative. `Checkout`
  raises `Checkout::InvalidDiscountError` for anything else, such as `4.5` or `nil`.
- `to_s` returns a label for the breakdown.

The basket is a frozen snapshot with `count(code)`, `unit_price(code)` and `subtotal`. Every
rule sees the same basket and the discounts add up, so the order of rules doesn't matter.
Offers that overlap on the same unit stack, and the total never goes below zero; decision 8
explains why and when to change that.

To add a rule:

1. Write its spec in `spec/rules/` and its class in `lib/rules/`.
2. Pass an instance to `Checkout.new`, and add it to `bin/checkout` if it is a live offer.

`Checkout` doesn't change. For example, $5 off when the undiscounted subtotal is $50 or more:

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

Every rule sees prices before any offer. A rule that needs the amount after other offers,
such as "10% off the whole order", or one that needs to list the basket's contents, such as
"cheapest of any 3 items free", doesn't fit without changing `Checkout` or `Basket`.
Decision 1 lists these limits.

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
