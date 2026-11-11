# Clarifications

Questions I asked the Matic team in Slack and answers.

Each entry has the question, the assumption I stated when asking, the answer (verbatim), and what it means for the work. Design decisions and their trade-offs live in `docs/decisions.md` (Task 1) and in the spec under `docs/link-shortener/` (Task 2).

Status key: **Confirmed** (answer matches my assumption), **Changed** (answer overrides it), **My call** (left to me), **Unanswered** (my assumption stands).

## Task 1: Discounts

### 1. Can a rule span more than one product or the whole basket?

- **Assumption:** the design should allow cross-product rules, even though the two current ones are single-product.
- **Answer:** "Assume marketing team can come up with any new rules, including ones you invent."
- **Status:** Confirmed, and broader than I asked.
- **Implication:** a rule must be able to see the whole basket, not one product. Rule shapes cannot be enumerated in advance, so adding a rule has to mean writing new code without changing `Checkout`. I will add one invented rule of a different shape to prove this.

### 2. Who adds new rules: engineers in code, or marketing through configuration or a UI?

- **Assumption:** engineers add rules in code; a self-service DSL or admin UI is out of scope.
- **Answer:** "Your call. Whatever you think fits your version of MVP."
- **Status:** My call.
- **Implication:** rules are Ruby objects added by engineers. No DSL and no admin UI in the MVP; the reasoning and the conditions for revisiting it go in `docs/decisions.md`. The "interactive interface" nice-to-have is a small command-line script.
