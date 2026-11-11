# frozen_string_literal: true

module Rules
  # Buy the trigger product, get percent off the target product: one
  # discounted target unit per trigger unit scanned. The discount is rounded
  # per unit, half away from zero.
  class PercentOffWithPurchase
    def initialize(trigger:, target:, percent:)
      raise ArgumentError, "percent must be between 0 and 100, got #{percent.inspect}" unless (0..100).cover?(percent)

      @trigger = trigger
      @target = target
      @percent = percent
    end

    def discount(basket)
      units = [basket.count(@trigger), basket.count(@target)].min
      units * (basket.unit_price(@target) * Rational(@percent, 100)).round
    end

    def to_s
      "#{@target}: #{@percent}% off with each #{@trigger}"
    end
  end
end
