# Code review (Task 1)

A critical review of the checkout in `lib/`, `spec/` and `bin/`, written from the point of view
of a senior Ruby reviewer who did not write the code. It was done at commit `da4613f`, and file
and line references point at that commit.

At that commit `bundle exec rspec` passed (56 examples) and `bundle exec rubocop` reported no
offenses. The numbers in the findings come from a probe script run against that commit.

## Requirements

The `Checkout.new(rule1, rule2, …)` / `scan` / `total` interface is there, all three example
totals pass, and there is an interactive CLI. The one gap is that `total` returns `2245`, not
`$22.45`. That is decision 3 and the README says so. It is still the first thing a grader's own
script will trip on: `co.total == 22.45` is false.

## Findings

### High

#### 1. `total` is built from a Hash keyed by rule

`lib/checkout.rb:29-36`

- **What's wrong:** how often a rule counts depends on object equality.
  - The same instance passed twice is applied once: FR, FR → 311.
  - Two separate `BuyOneGetOneFree.new('FR')` objects are both applied: FR, FR → 0.
  - A rule written with `Data.define` is common modern Ruby. Two equal instances of it become
    one Hash key and count once: 211 where 111 is expected.
- **Why it matters:** decision 1 says total = subtotal − the sum of discounts, and that isn't
  true here. Results depend on how a future rule author implements `==`/`hash`, which is the
  extension point the design is built around. It also means `total` depends on a display method
  (`discounts` with its `reject zero`), and it builds two snapshots per call.
- **Smallest fix:** in `total`, take one snapshot and compute
  `basket.subtotal - @rules.sum { _1.discount(basket) }`. Make `discounts` return an array of
  `[rule, cents]` pairs. Add a spec that pins down what passing the same rule twice should do.

#### 2. Nothing stops the total going below zero

`lib/checkout.rb:35`

- **What's wrong:** BOGOF on FR plus `BulkPrice.new('FR', min_quantity: 2, price: 100)` gives
  FR, FR → **−111**. The store pays the customer.
- **Why it matters:** decision 8 accepts that overlapping offers double-discount. It doesn't
  say the total can go negative, and nothing in the docs mentions it. Marketing changes offers
  often, so two offers on one product is likely.
- **Smallest fix:** `[…, 0].max` in `total`, plus a spec. The CLI breakdown then won't add up
  to the total in that case, so say so.

#### 3. The "integer cents, never negative" contract is written down but never checked

`lib/checkout.rb:31`, `lib/rules/bulk_price.rb:8-12`

- **What's wrong:**
  - The assignment literally says "$4.50", so `BulkPrice.new('SR', min_quantity: 3, price:
    4.50)` is an easy mistake. SR×3 then gives the Float `13.5`: it looks right as dollars but
    is actually cents, and the CLI prints `$0.13`. Add a CF and the total is `1136.5`.
  - `price: -100` gives −300.
  - `PercentOffWithPurchase` validates its arguments; `BulkPrice` and `BuyOneGetOneFree` don't.
- **Why it matters:** decision 2 lists "the unit is implicit" as an accepted trade-off. This is
  exactly how that trade-off fails.
- **Smallest fix:** one guard in `Checkout` that raises unless each rule returns an `Integer`
  that is `>= 0`. That covers every future rule in one place.

### Medium

#### 4. A misspelled rule code either crashes every checkout or does nothing

`lib/basket.rb:12-14`

- **What's wrong:**
  - `BuyOneGetOneFree.new('FT')` raises `KeyError` on every `total`, even for an empty basket.
  - `BulkPrice.new('SRR', …)` never applies and raises nothing (SR×3 → 1500).
  - In `PercentOffWithPurchase`, a typo in the trigger does nothing; a typo in the target
    raises.
- **Why it matters:** decision 5 accepts this. The silent half is the worse failure: an offer
  marketing has announced quietly never fires, and nobody finds out until a customer
  complains.
- **Smallest fix:** make `Basket#count` call `@catalog.fetch(code)` before reading the count.
  Every typo then fails loudly and the same way, and the CLI spec would catch a typo in the
  live offers.

#### 5. The real limit on extensibility is `Basket`, and it is narrow

`lib/basket.rb:5-23`

`Basket` offers only `count(code)`, `unit_price(code)` and `subtotal`.

- **Rule that does not fit: "10% off the whole order"** (or "spend $50 after offers, get $5
  off"). A rule only sees the price before other discounts, so it would also discount the free
  tea. Supporting it needs rules to see each other's results, which means ordering or phases,
  which means changing `Checkout`.
- The README's own `AmountOffOver` example already has this problem. FR FR CF CF CF CF has a
  subtotal of 5114 but costs 4803 after BOGOF, and it still gets $5 off for being "over $50".
- **Other rules that don't fit:**
  - "Cheapest of any 3 items free": `Basket` can't list what's in it, so `basket.rb` would
    have to change.
  - Coupon codes and loyalty prices: there's no input besides the basket.
  - "Buy CF, get a free FR you didn't scan": a discount can't add an item.
- **Smallest fix:** reword the README example to say "undiscounted subtotal", and add this
  limitation to decision 1's trade-offs.

#### 6. Behaviour the docs claim but no spec checks

`spec/`

- **What's missing:**
  - Decision 6's $21.07 for all three rules together. It is correct, but
    `git log -S2107 -- spec` is empty. `plan.md:274` lists 1209 and 2107 as checks, and
    neither was ever written.
  - That rule order doesn't change the total (decision 1 and `README.md:65`).
  - Duplicate rules, two rules on one product, negative totals.
  - The misspelled-rule-code behaviour that decision 5 describes.
  - The README's `AmountOffOver`.
- **Smallest fix:** one acceptance example with all three rules (FR FR CF CF → 2107), and one
  `Checkout` spec that reverses the rule order and gets the same total.

#### 7. The docs say things the code doesn't do

Beyond what is covered above:

- `clarifications.md:16` promises an invented rule "of a different shape".
  `PercentOffWithPurchase` has the same shape as the other two: counts × unit price for named
  codes. The only rule that works on the whole basket exists as README text, not code.
- `plan.md:285` says adding a rule touches only `lib/rules/` and its spec. `README.md:71`
  correctly says a live offer also touches `bin/checkout`.
- `README.md:32` uses `transform_keys(&:to_s)`, which merges rules that share a label (see 11).
- **Smallest fix:** correct those three lines, or move `AmountOffOver` into `lib/rules/` with a
  spec. That would be the real proof that a new shape fits.

#### 8. Specs that test how the code works rather than what it does

- `spec/basket_spec.rb:29-31` and `spec/product_spec.rb:15-17` assert `be_frozen`. `Basket` has
  no methods that change it, so these tests protect nothing a caller could see.
- `spec/product_spec.rb:6-13` copies the whole catalog. Any price change means editing two
  files, and the acceptance totals already pin the prices.
- `spec/checkout_spec.rb:61-68` fixes the Hash-keyed-by-rule return shape that causes finding 1.
- **Smallest fix:** delete the freeze specs, cut the catalog spec down to "keyed by its own
  code, priced in Integer cents", and update the `discounts` spec after fixing 1.

### Low

#### 9. `money` is wrong for negative amounts

`bin/checkout:14-16`

−111 prints as `$-2.89`, and −50 as `$-1.50`. Finding 2 makes negatives reachable. **Fix:** take
the sign out first, then `cents.abs.divmod(100)`.

#### 10. An empty line reports `Unknown product code: ""`

`bin/checkout:31-33`

Pressing Enter twice in the interactive session prints an error. **Fix:** `next if
code.empty?`.

#### 11. The bulk price label leaves out the price

`lib/rules/bulk_price.rb:21-23`

Two SR bulk offers (450 and 400, both at 3+) appear as two identical CLI rows. The README idiom
merges them into one row showing 300, while the total takes off 450. The CLI exists to validate
offers, and here you can't see the offer's price. **Fix:** include `@price` (in cents) in the
label.

#### 12. The current offers are wired up in three places

`bin/checkout:22-25`, `spec/acceptance/checkout_spec.rb:10-15`, `README.md:24-27`

The acceptance spec tests its own copy, not what actually ships. **Fix:** one shared list of
current offers, used by both `bin/checkout` and the acceptance spec.

#### 13. Nothing stops `trigger == target`

`lib/rules/percent_off_with_purchase.rb:17`

Each coffee triggers its own discount, so `(CF, CF, 50)` makes every coffee half price (one CF
→ 561). That's not "second one half price". `percent` also accepts Floats, and
`Rational(33.3, 100)` isn't exact. **Fix:** raise when `trigger == target`, and require an
Integer percent.

#### 14. Nit: inconsistent namespacing

`Product`, `CATALOG`, `Basket` and `Checkout` are top-level constants, while the rules live
under `Rules::`.

## Questions an interviewer is most likely to ask

1. "Why does `total` return 2245 when the spec table says $22.45? What happens when I run
   `co.total == 22.45`?"
2. "Marketing wants BOGOF and a $1 Fruit Tea deal at the same time, then '10% off the whole
   order'. What happens today, and how would the design change?" They'll be looking for:
   stacking, negative totals, `BestOf`, rules running in phases, design C.
3. "What happens if I pass the same rule twice, or a rule that returns `4.5`, or I mistype a
   code? What does `Checkout` actually promise, and who enforces it?"
4. "Why discount calculators instead of a line-item pipeline? How would you print a receipt
   line per item?" (decision 7's "revisit when").
5. "The assignment says you'll discuss AI use, and `CLAUDE.md` is committed. Which decisions
   came from the AI, and where did you overrule it?"

## Follow-up

The High and Medium findings were fixed on the `review-fixes` branch, one commit each, test
first, with `bundle exec rspec` and `bundle exec rubocop` green before every commit. The Low
findings were left as they are.

| Finding | Status | Commit |
|---|---|---|
| Requirements: `total` in cents | Fixed: `total`, `subtotal` and `discounts` return Float dollars; `co.total == 22.45` is true (decision 3) | `86d3533` |
| 1. Hash keyed by rule | Fixed: every rule passed counts; `discounts` returns `[rule, amount]` pairs | `f4d17a5` |
| 2. Negative total | Fixed: `total` never goes below zero (decision 8) | `2cf5d12` |
| 3. Unchecked discount contract | Fixed: `Checkout` raises `InvalidDiscountError`; `BulkPrice` validates `price:` and `min_quantity:` | `78b1f05`, `3fba287` |
| 4. Misspelled rule codes | Fixed: `Basket#count` and `#unit_price` raise `KeyError` (decision 5) | `0a8be49` |
| 5. Narrow `Basket` | Documented, not changed: README example reworded, limits listed in decision 1 | `afda9f8` |
| 6. Untested claims | Fixed: all three rules and rule order in acceptance specs; duplicates, the zero floor and typos covered with their fixes. The README's `AmountOffOver` still has no spec | `ffbd4c3` |
| 7. Docs vs code | Fixed | `afda9f8`, `f4d17a5` |
| 8. Implementation-detail specs | Fixed | `f3d28c1`, `f4d17a5` |
| 9. `money` and negatives | Not fixed. No longer reachable: totals and discounts can't be negative | |
| 10. Empty CLI line | Not fixed | |
| 11. Bulk price label | Not fixed. The README no longer merges rows, but two SR bulk offers still print identical labels | |
| 12. Offers wired in three places | Not fixed | |
| 13. `trigger == target` | Not fixed | |
| 14. Namespacing | Not fixed | |

Interviewer question 1 changes with the first fix. Expect instead: "Why Float dollars, and
what does `co.subtotal - co.total` give?" It gives `3.1099999999999994` for the first example;
decision 3 records that trade-off.
