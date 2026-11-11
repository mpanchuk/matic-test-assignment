# Matic Insurance Test Assignment

Our goal is to get a sense of your thought process, code design, and execution. Using AI tools is encouraged, and we'll talk about how you used them during the feedback conversation.

You don't need to deliver a perfect solution. We trust your judgment on how complete the implementation should be. If you decide to reduce the scope and deliver a partial solution, please tell us before the feedback session.

We expect that you invest no more than 2 hours of focused time to work on the test assignment. Please share the source code for your solutions in a Git repository.

---

## Task 1: Design/Architecture – Discounts

A grocery store sells the following products:

| Product      | Code | Price  |
|--------------|------|--------|
| Fruit Tea    | FR   | $3.11  |
| Strawberries | SR   | $5.00  |
| Coffee       | CF   | $11.23 |
| Apple Juice  | AJ   | $7.25  |

The marketing team is pushing hard to come up with new offers. So far, we have the following rules:

- **Fruit Tea:** buy one, get one free.
- **Strawberries:** if you buy 3 or more, the price of each drops to $4.50.

These rules are independent of each other, and both can apply to the same checkout.

We expect the marketing team to keep coming up with new ideas for boosting sales.

Please implement a checkout system that meets the requirements above, can be extended with new rules, and provides an interface similar to the following:

```ruby
co = Checkout.new(rule1, rule2, ...)
co.scan('FR')
co.scan('CF')
...
total_cost = co.total
```

An interactive interface that allows validating current offers is nice to have.

### Examples

| Items              | Total  |
|--------------------|--------|
| FR, SR, FR, FR, CF | $22.45 |
| FR, FR             | $3.11  |
| SR, SR, FR, SR     | $16.61 |

---

## Task 2: Planning/Requirements – Link Shortener

The Call Center team has asked you to help build a link shortener. Your task is to create a spec, a rough architecture, and a rollout plan for this service.

Before the implementation starts, the team wants to know what will be delivered and how much it will cost.

You can deliver the plan in any format you like. Feel free to reach out on Slack if you have any questions or need more information.
