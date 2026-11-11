# Decisions (Task 1)

Status: **Final**. This file records the design choices for the checkout and why each one was
made. Options and worked examples are in [`plan.md`](plan.md). The answers these decisions
rest on are in [`clarifications.md`](clarifications.md).

Every entry has five parts: decision, options considered, why, trade-off accepted, and when to
revisit.

## 1. Rules are discount calculators over a read-only basket

- **Decision:** a rule is any object with `#discount(basket)`, which returns integer cents
  (never negative), and `#to_s`, its label. `Checkout#total` is the subtotal minus the sum of
  the discounts. Every rule sees the same frozen basket.
- **Options considered:**
  - (A) discount calculators, as above.
  - (B) a price pipeline that rewrites line items in constructor order.
  - (C) rules claim specific units, and `Checkout` rejects claims that overlap.
  - Per-product strategies.
- **Why:**
  - The assignment says the rules are independent and can both apply, and with A the order of
    rules can't matter.
  - Adding a rule is one class plus its spec, and `Checkout` never changes (clarification 1).
  - Each rule is a pure function that can be tested on its own.
- **Trade-off accepted:** offers that overlap on the same unit stack, and no rule can see what
  another rule did.
- **Revisit when:** marketing asks for offers that must not combine (see 8).

## 2. Money is integer cents

- **Decision:** prices, discounts and totals are Integer cents. Percentage discounts are
  computed with `Rational` and rounded per unit, half away from zero.
- **Options considered:** Float, BigDecimal, Rational, a Money value object, integer cents.
- **Why:**
  - Integer cents are exact for addition, subtraction and multiplication by an integer, and
    need no dependency.
- **Trade-off accepted:** the unit is implicit, and callers must know it's cents.
- **Revisit when:** a second currency appears (see 9).

## 3. `Checkout#total` returns Integer cents

- **Decision:** `co.total # => 2245`. Only the CLI formats it as `$22.45`.
- **Options considered:**
  - Integer cents.
  - Float dollars (`cents / 100.0` at the end).
  - A Money object.
  - A formatted string.
- **Why:** there is no conversion and no float anywhere. It's the minor-units convention
  payment APIs use. Formatting is a display concern.
- **Trade-off accepted:** it reads differently from the "$22.45" in the assignment table, and
  the method name doesn't say "cents".
- **Revisit when:** callers need a value that formats itself (see 9).

## 4. The catalog is injected, with a default

- **Decision:** `Checkout.new(*rules, catalog: CATALOG)`. `CATALOG` is a frozen hash of
  `Product(code, name, price)`.
- **Options considered:**
  - A constant used directly inside `Checkout`.
  - A required argument, which would break the assignment interface.
  - An optional keyword with a default.
- **Why:** the assignment interface still works, tests can use their own products, and the CLI
  can list product names.
- **Trade-off accepted:** one keyword that isn't in the assignment.
- **Revisit when:** prices come from a database or a service. The catalog then becomes an
  object that answers `fetch(code)`.

## 5. An unknown product code raises at scan

- **Decision:** `scan('XX')` raises `Checkout::UnknownProductError` and leaves the basket
  unchanged. The CLI catches it, prints it and continues.
- **Options considered:** raise at scan, ignore silently, ignore with a warning, raise at
  `total`.
- **Why:** ignoring the code undercharges and hides a scanner bug. Raising at `total` is too
  late to say which scan was wrong.
- **Trade-off accepted:**
  - Callers must handle the error.
  - Rule codes are not checked against the catalog, so a rule with a misspelled code may
    simply never apply.
- **Revisit when:** non-engineers configure rules. At that point rule codes should be
  checked when the `Checkout` is built.

## 6. Cross-product rule: one discounted coffee per Fruit Tea

- **Decision:** `PercentOffWithPurchase.new(trigger: 'FR', target: 'CF', percent: 20)`. The
  number of discounted coffees is `min(count(FR), count(CF))`. Every scanned Fruit Tea counts,
  including one made free by BOGOF.
- **Options considered:**
  - One per tea, with all teas counting.
  - One per tea, with only paid teas counting.
  - Any tea discounts every coffee.
- **Why:**
  - Limiting it to one coffee per tea caps what the offer costs.
  - Counting every scanned tea keeps the rule independent of BOGOF (see 1).
  - The rule is invented to show that a rule of a different shape needs no change to
    `Checkout` (clarification 1).
- **Trade-off accepted:** a free tea still earns a coffee discount, so FR, FR, CF, CF comes to
  $21.07.
- **Revisit when:** marketing defines a real cross-product offer.

## 7. The CLI shows a breakdown per offer

- **Decision:** `bin/checkout` reads one code per line and upcases it. After each scan it
  prints the subtotal, each offer that fired with its discount, and the total.
- **Options considered:** a running total only, or a breakdown per offer.
- **Why:** to check that the current offers work, you need to see which offer fired. That
  costs one `#to_s` label per rule and two read-only methods on `Checkout`: `#subtotal` and
  `#discounts`.
- **Trade-off accepted:** `Checkout`'s public interface grows beyond the assignment's
  `scan` and `total`.
- **Revisit when:** a receipt per line item is needed. Rules would then have to report which
  units they discounted, which moves towards design B or C.

## 8. Out of scope: exclusivity between offers

- **Decision:** all offers stack. Nothing stops two offers from applying to the same unit.
- **Options considered:**
  - Stacking only.
  - A `BestOf.new(a, b)` wrapper rule for specific pairs of offers.
  - Claims at the unit level with conflict resolution (design C).
- **Why:**
  - No current offer overlaps on the same unit.
  - Claims need a conflict policy from the business.
  - A greedy resolution gives surprising totals: $25.57 against a best possible $24.18 for
    FR, FR, CF, CF.
- **Trade-off accepted:** a future offer that overlaps on the same unit will double-discount
  until it is handled.
- **Revisit when:** marketing first says two offers can't combine. Add `BestOf`, with
  `Checkout` unchanged. If many offers need it, move to claims.

## 9. Out of scope: a Money class

- **Decision:** no Money value object. Use plain integer cents, with formatting done only in
  the CLI.
- **Options considered:** a Money class (cents, currency, formatting), or integer cents.
- **Why:** there is one currency. A class would add about 20 lines and more to explain,
  without changing any result.
- **Trade-off accepted:** the unit is implicit, and formatting lives in one helper in the CLI.
- **Revisit when:** a second currency appears, or money needs formatting in more than one
  place.

## 10. Out of scope: a DSL or admin UI for rules

- **Decision:** rules are Ruby classes written by engineers and wired up in code through
  `Checkout.new`.
- **Options considered:**
  - Ruby classes.
  - A config file that maps to rule classes.
  - A DSL.
  - An admin UI.
- **Why:**
  - The team left this to me (clarification 2).
  - Marketing can invent any shape of rule (clarification 1). A config file, DSL or UI can
    only set parameters for rule shapes that already exist as code, so new shapes need an
    engineer anyway.
  - It fits the time box.
- **Trade-off accepted:** every new offer needs an engineer and a deploy.
- **Revisit when:** offers launch often enough that deploys become the bottleneck, and most
  new offers reuse existing rule shapes. Then add a config layer over the existing rule
  classes, and possibly a UI later.
