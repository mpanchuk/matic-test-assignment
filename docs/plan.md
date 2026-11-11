# Task 1 plan: checkout with pricing rules

Status: implemented; all eight steps below are done. Decisions and their reasoning are in
[`decisions.md`](decisions.md). Requirements are in [`assignment.md`](assignment.md) and
[`clarifications.md`](clarifications.md).

Changes made during implementation, beyond the shape below:

- `BulkPrice` floors the discount at 0 when the bulk price isn't below the catalog price, so
  a discount is never negative (decision 1).
- `PercentOffWithPurchase` raises `ArgumentError` unless `percent` is in `0..100`.
- `bin/checkout` lists the products at start, and syncs stdout so an error stays in order
  with the breakdown when output is piped. It formats money with named format tokens, as
  RuboCop's default style requires.

## Context

Task 1 has a 75-minute time box and is judged on code design and extensibility. Fixed before
this plan:

- The public interface from the assignment: `Checkout.new(rule1, rule2, ...)`, `#scan(code)`,
  `#total`.
- Rules are Ruby objects written by engineers. No DSL, no admin UI.
- Marketing can invent any rule, so a rule sees the whole basket, and adding a rule must not
  change `Checkout`.
- The interactive interface is a small command-line script, built last.

The assignment examples, checked in cents: FR, SR, FR, FR, CF → 2245; FR, FR → 311;
SR, SR, FR, SR → 1661.

## Options considered

### Shared by all designs

- **Money is integer cents** (`311`). Float can't represent 3.11 exactly. BigDecimal is a
  default gem on Ruby 3.3 but a bundled gem from 3.4, which would make it a runtime
  dependency. A Money class is premature with one currency. Percentages are computed with
  `Rational` and rounded per unit, half away from zero: 20% off 1123¢ is 225¢, so each coffee
  costs $8.98.
- **Catalog**: `Product = Data.define(:code, :name, :price)` and a frozen `CATALOG`, injected
  as `Checkout.new(*rules, catalog: CATALOG)`. The assignment interface still works, and tests
  can pass their own products.
- **Unknown code**: `scan('XX')` raises `Checkout::UnknownProductError` and leaves the basket
  unchanged. Ignoring the code would undercharge and hide a scanner bug. Raising at `total`
  is too late to say which scan was wrong.

### Rule abstraction

Each design below implements the two assignment rules plus an invented cross-product rule,
"buy Fruit Tea, get 20% off Coffee". All three are compared on the basket FR, FR, CF, CF
(subtotal $28.68) with all three rules active.

#### A. Discount calculators

A rule receives a frozen, read-only basket (`count(code)`, `unit_price(code)`, `subtotal`)
and returns its discount in integer cents. Discounts add up, and every rule sees the same
original basket:

```ruby
total = basket.subtotal - rules.sum { |rule| rule.discount(basket) }

class BuyOneGetOneFree          # .new('FR')
  def discount(basket)
    basket.count(@code) / 2 * basket.unit_price(@code)
  end
end

class BulkPrice                 # .new('SR', min_quantity: 3, price: 450)
  def discount(basket)
    qty = basket.count(@code)
    return 0 if qty < @min_quantity

    qty * (basket.unit_price(@code) - @price)
  end
end

class PercentOffWithPurchase    # .new(trigger: 'FR', target: 'CF', percent: 20)
  def discount(basket)
    units = [basket.count(@trigger), basket.count(@target)].min
    units * (basket.unit_price(@target) * Rational(@percent, 100)).round
  end
end
```

- Comparison basket: **$21.07**. Both free and paid Fruit Teas count as triggers.
- Pros:
  - The order of rules doesn't matter, which matches "independent rules".
  - `Checkout` stays about 15 lines and never changes.
  - Each rule is a pure function of the basket and can be tested without `Checkout`.
  - Adding a rule means one class with one method.
- Cons: offers that overlap on the same unit stack, and there is no exclusivity. If two
  specific offers must not combine, a `BestOf.new(a, b)` wrapper rule handles it without
  changing `Checkout`.

#### B. Price pipeline

Each scanned unit becomes a `LineItem = Data.define(:code, :price)`. A rule takes the list of
items and returns a new list with prices changed. Rules run in constructor order:

```ruby
total = rules.reduce(line_items) { |items, rule| rule.apply(items) }.sum(&:price)

class BuyOneGetOneFree
  def apply(items)
    seen = 0
    items.map do |item|
      next item unless item.code == @code

      seen += 1
      seen.even? ? item.with(price: 0) : item
    end
  end
end

class BulkPrice
  def apply(items)
    return items if items.count { _1.code == @code } < @min_quantity

    items.map { _1.code == @code ? _1.with(price: @price) : _1 }
  end
end

class PercentOffWithPurchase
  def apply(items)
    left = items.count { _1.code == @trigger }
    items.map do |item|
      next item unless item.code == @target && left.positive?

      left -= 1
      item.with(price: (item.price * Rational(100 - @percent, 100)).round)
    end
  end
end
```

- Comparison basket: $21.07, or **$23.32** if the cross rule counts only paid teas and
  BOGOF runs first. With the order swapped it's $21.07 again, so the total depends on the
  order of rules.
- Pros:
  - "Price drops to $4.50" is written literally.
  - Every unit ends with a final price, so a receipt comes for free.
  - A rule can see what earlier rules did.
- Cons:
  - The order dependence is hidden coupling between rules and goes against "independent".
  - Each rule keeps counters and has to pass through items it doesn't touch.
  - Specs need line-item fixtures.

#### C. Claims with exclusivity

Units have identity (the scan index). A rule returns claims on specific units. `Checkout`
accepts the largest claims first and skips any claim that reuses a unit already claimed:

```ruby
class BuyOneGetOneFree
  def claims(basket)
    basket.units(@code).each_slice(2).filter_map do |pair|
      Claim.new(pair, pair.last.price) if pair.size == 2
    end
  end
end

class BulkPrice
  def claims(basket)
    units = basket.units(@code)
    return [] if units.size < @min_quantity

    [Claim.new(units, units.sum { _1.price - @price })]
  end
end

class PercentOffWithPurchase
  def claims(basket)
    triggers = basket.units(@trigger)
    targets  = basket.units(@target).first(triggers.size)
    targets.zip(triggers).map do |cf, fr|
      Claim.new([fr, cf], (cf.price * Rational(@percent, 100)).round)
    end
  end
end
```

- Comparison basket: **$25.57**. The greedy pass takes BOGOF (311¢) and blocks both coffee
  claims. The best result for the customer would be $24.18 (2 × 225¢). Finding the best
  result in general is weighted set packing, so a greedy pass will sometimes surprise people.
- Pros: no unit is discounted twice, by construction. Each claim gives a receipt line.
- Cons:
  - It needs a conflict policy the business hasn't asked for.
  - It puts the most logic in `Checkout` and is the hardest to explain.
  - It doesn't fit the time box.

#### Rejected early

Per-product strategies (`applies_to?(code)` plus a per-code price function) can't express
cross-product rules.

### Other open points

- **What `total` returns**:
  - Integer cents (`2245`): exact, with no conversion; the CLI formats it.
  - Float dollars (`22.45`, computed as `cents / 100.0` at the end): matches the assignment
    table, but callers doing arithmetic on it get float errors again.
  - A Money object: exact and readable, but about 20 more lines for one currency.
- **Meaning of the cross-product rule**:
  - One discounted coffee per tea, every scanned tea counts: the rule stays independent.
  - One coffee per tea, paid teas only: couples the rule to BOGOF, and only works with B or C.
  - Any tea discounts all coffees: simpler and more generous.
- **CLI output**:
  - A breakdown per offer: you can see which offer fired; each rule needs a label and
    `Checkout` gets two read-only methods.
  - A running total only: smallest interface, but you can't see which offer applied.

## Plan

**Gate:** no code until `decisions.md` is final and the acceptance specs are written. After
that, follow the steps below, test first, one commit each.

### Decisions

1. **Design A.** A rule is any object with `#discount(basket) -> Integer cents (>= 0)` and
   `#to_s` (its label). Every rule sees the same frozen basket, discounts add up, and the order
   of rules doesn't matter.
2. **Money is integer cents everywhere**, and **`total` returns Integer cents** (`2245`).
   Percentages are computed with `Rational` and rounded per unit, half away from zero.
3. **Catalog injected with a default**: `Checkout.new(*rules, catalog: CATALOG)`.
4. **Unknown code**: `scan` raises `Checkout::UnknownProductError` and leaves the basket
   unchanged.
5. **Cross-product rule**: one discounted coffee per Fruit Tea, `min(teas, coffees)`. Every
   scanned tea counts, including ones made free by BOGOF.
6. **CLI shows a breakdown per offer**: subtotal, each offer that fired with its discount, and
   the total.

### Shape

- `lib/product.rb`: `Product = Data.define(:code, :name, :price)` and a frozen `CATALOG`
  (FR 311, SR 500, CF 1123, AJ 725).
- `lib/basket.rb`: an immutable snapshot of the scanned codes plus the catalog, with
  `count(code)`, `unit_price(code)` and `subtotal`. It is the only thing rules depend on.
- `lib/checkout.rb`:
  - `initialize(*rules, catalog: CATALOG)`.
  - `scan(code)` checks the code against the catalog, then appends it.
  - `subtotal`.
  - `discounts` maps each rule to its non-zero discount, for the CLI.
  - `total = subtotal - discounts.values.sum`.
  - A frozen `Basket` is built per call, so no rule can change state.
- `lib/rules/buy_one_get_one_free.rb`: `count / 2 * unit_price`.
- `lib/rules/bulk_price.rb`: `(code, min_quantity:, price:)`. Below the minimum it's 0;
  otherwise `qty * (unit_price - price)`.
- `lib/rules/percent_off_with_purchase.rb`: `(trigger:, target:, percent:)`, computed as
  `min(count(trigger), count(target)) * (unit_price(target) * Rational(percent, 100)).round`.
- `bin/checkout`:
  - Reads codes line by line and upcases them.
  - After each scan it prints the breakdown.
  - It catches `UnknownProductError`, prints it, and keeps going.
  - It formats money without floats: `format('$%d.%02d', *cents.divmod(100))`.

### Out of scope

Each of these is recorded in `decisions.md` with when to revisit it.

- **Exclusivity between offers.** The path to it is a `BestOf.new(a, b)` wrapper rule with
  `Checkout` unchanged, then claims (design C) if exclusivity at the unit level is ever needed.
- **A Money class.**
- **A DSL or admin UI.**

### Steps

One commit each, with rspec and rubocop green before each. Specs are never edited just to
make them pass.

1. Product and `CATALOG`.
2. `Checkout#scan` / `#total` with no rules (sum of prices), plus `UnknownProductError`.
3. `Basket` and `BuyOneGetOneFree` (FR, FR → 311).
4. `BulkPrice`: all three assignment examples go green (2245, 311, 1661).
5. `PercentOffWithPurchase` (FR, CF → 1209; FR, FR, CF, CF → 2107).
6. `#to_s` labels and `Checkout#subtotal` / `#discounts`.
7. `bin/checkout` CLI.
8. README: usage and how to add a rule.

### Verification

- `bundle exec rspec`: the acceptance specs, plus unit specs for each rule and for `Basket`.
- `bundle exec rubocop`.
- `printf 'FR\nSR\nFR\nFR\nCF\n' | bin/checkout` shows BOGOF −$3.11 and a total of $22.45.
  Entering `XX` prints an unknown-product message and the session continues.
- Live demo check: adding a new rule touches only `lib/rules/` and its spec. `Checkout` is not
  in the diff.
