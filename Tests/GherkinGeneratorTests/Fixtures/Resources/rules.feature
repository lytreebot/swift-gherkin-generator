@pricing @business-rules
Feature: Order Pricing Engine
  As a product manager
  I want pricing rules applied consistently
  So that customers are charged correctly

  Background:
    Given the pricing engine is initialized
    And the current date is "2025-06-15"

  Rule: Standard pricing for retail customers
    Retail customers pay the listed catalog price
    with no volume discounts applied.

    Background:
      Given the customer type is "retail"

    Scenario: Single item at catalog price
      Given the product "Running Shoes" has a catalog price of 120.00 EUR
      When the customer adds 1 pair to the order
      Then the line total is 120.00 EUR

    Scenario: Multiple items without discount
      Given the product "Running Shoes" has a catalog price of 120.00 EUR
      When the customer adds 3 pairs to the order
      Then the line total is 360.00 EUR
      And no volume discount is applied

  @wholesale
  Rule: Volume discounts for wholesale customers
    Wholesale customers receive tiered discounts
    based on order quantity thresholds.

    Background:
      Given the customer type is "wholesale"

    Scenario: Small wholesale order — no discount
      Given the product "Running Shoes" has a catalog price of 120.00 EUR
      When the customer orders 5 pairs
      Then the line total is 600.00 EUR
      And the discount rate is 0%

    @discount
    Scenario: Medium wholesale order — 10% discount
      Given the product "Running Shoes" has a catalog price of 120.00 EUR
      When the customer orders 20 pairs
      Then the discount rate is 10%
      And the line total is 2160.00 EUR

    @discount
    Scenario: Large wholesale order — 20% discount
      Given the product "Running Shoes" has a catalog price of 120.00 EUR
      When the customer orders 100 pairs
      Then the discount rate is 20%
      And the line total is 9600.00 EUR

  Rule: Seasonal promotions
    During promotional periods, additional discounts
    are stacked on top of existing pricing rules.

    Background:
      Given a seasonal promotion "Summer Sale" is active
      And the promotion discount is 15%

    Scenario: Retail customer during promotion
      Given the customer type is "retail"
      And the product "Running Shoes" has a catalog price of 120.00 EUR
      When the customer adds 1 pair to the order
      Then the promotional discount of 15% is applied
      And the line total is 102.00 EUR

    Scenario: Wholesale customer during promotion
      Given the customer type is "wholesale"
      And the product "Running Shoes" has a catalog price of 120.00 EUR
      When the customer orders 20 pairs
      Then the volume discount of 10% is applied first
      And the promotional discount of 15% is applied on the reduced price
      And the line total is 1836.00 EUR
