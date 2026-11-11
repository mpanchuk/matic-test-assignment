# Matic test assignment

Take-home for a senior Ruby role. Task 1 is a checkout with pricing rules
(code in lib/). Task 2 is a planning document (docs/link-shortener/).

## Read first
- docs/assignment.md: the requirements, source of truth
- docs/clarifications.md: answers from the team and my assumptions
- docs/decisions.md: design decisions, once it exists. Don't contradict it;
  if you disagree, say so and wait.

## Stack
- Plain Ruby, no Rails, no runtime gems
- RSpec for tests, RuboCop for style

## Commands
- bundle exec rspec
- bundle exec rubocop

## How we work
- Plan before code; wait for my approval on anything structural
- Test first; never edit a spec just to make it pass
- One small change per commit; rspec and rubocop green before each
- No speculative abstractions; ask instead of guessing requirements
