# Shopping cart feature — core e-commerce flow
# Last updated: 2025-03-15

@e2e @smoke @cart
Feature: Shopping Cart Management
  As an online shopper
  I want to manage items in my shopping cart
  So that I can purchase the products I need

  Background:
    Given a logged-in customer with email "shopper@example.com"
    And the product catalog is loaded
    And the shopping cart is empty

  @happy-path
  Scenario: Add a single product to the cart
    Given the product "Wireless Headphones" priced at 79.99 EUR
    When I add the product to my cart
    Then the cart contains 1 item
    And the cart total is 79.99 EUR
    But no discount is applied

  @happy-path
  Scenario: Add multiple different products
    Given the product "Wireless Headphones" priced at 79.99 EUR
    And the product "USB-C Cable" priced at 12.50 EUR
    When I add "Wireless Headphones" to my cart
    And I add "USB-C Cable" to my cart
    Then the cart contains 2 items
    And the cart total is 92.49 EUR

  @negative
  Scenario: Cannot add out-of-stock product
    Given the product "Limited Edition Watch" is out of stock
    When I try to add "Limited Edition Watch" to my cart
    Then an error message "Product is currently unavailable" is displayed
    And the cart remains empty

  Scenario: Update product quantity in cart
    Given the product "Notebook" priced at 15.00 EUR
    And I have 1 "Notebook" in my cart
    When I update the quantity of "Notebook" to 3
    Then the cart contains 3 items
    And the cart total is 45.00 EUR

  Scenario: Remove a product from the cart
    Given I have the following items in my cart:
      | product             | quantity | price |
      | Wireless Headphones | 1        | 79.99 |
      | USB-C Cable         | 2        | 12.50 |
      | Notebook            | 1        | 15.00 |
    When I remove "USB-C Cable" from my cart
    Then the cart contains 2 items
    And the cart total is 94.99 EUR

  @api
  Scenario: Cart persists after page refresh
    Given I have 2 items in my cart
    When I refresh the page
    Then the cart still contains 2 items

  @api
  Scenario: Verify cart contents via API
    Given I have added "Wireless Headphones" to my cart
    When I request the cart contents via the API
    Then the response body is:
      """application/json
      {
        "items": [
          {
            "name": "Wireless Headphones",
            "quantity": 1,
            "price": 79.99,
            "currency": "EUR"
          }
        ],
        "total": 79.99
      }
      """
