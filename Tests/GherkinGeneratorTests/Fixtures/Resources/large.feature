@e2e @regression @performance
Feature: E-Commerce Platform End-to-End
  As a QA engineer
  I want comprehensive test coverage
  So that all critical paths are verified

  Background:
    Given the e-commerce platform is accessible
    And the test database is initialized with seed data

  @product-catalog @search
  Scenario: Search products by keyword
    Given I am on the home page
    When I enter "laptop" in the search field
    And I click the search button
    Then I should see at least 5 products in the results
    And all products should contain "laptop" in their title or description

  @product-catalog @search
  Scenario: Search returns no results for invalid keyword
    Given I am on the home page
    When I enter "xyzinvalidproduct123" in the search field
    And I click the search button
    Then I should see a "No products found" message

  @product-catalog @filter
  Scenario: Filter products by category
    Given I am viewing the product catalog
    When I select the "Electronics" category filter
    Then I should see only products in the "Electronics" category
    And the product count should be displayed

  @product-catalog @filter
  Scenario: Filter products by price range
    Given I am viewing the product catalog
    When I set the minimum price to 100
    And I set the maximum price to 500
    And I apply the price filter
    Then all displayed products should have prices between 100 and 500

  @product-catalog @filter
  Scenario: Apply multiple filters simultaneously
    Given I am viewing the product catalog
    When I select the "Computers" category filter
    And I set the price range from 500 to 2000
    And I select the "In Stock" availability filter
    Then I should see only products matching all filter criteria

  @product-catalog @sort
  Scenario: Sort products by price ascending
    Given I am viewing the product catalog
    When I select "Price: Low to High" from the sort dropdown
    Then products should be displayed in ascending price order

  @product-catalog @sort
  Scenario: Sort products by price descending
    Given I am viewing the product catalog
    When I select "Price: High to Low" from the sort dropdown
    Then products should be displayed in descending price order

  @product-catalog @sort
  Scenario: Sort products by name alphabetically
    Given I am viewing the product catalog
    When I select "Name: A to Z" from the sort dropdown
    Then products should be displayed in alphabetical order

  @product-catalog @details
  Scenario: View product details
    Given I am viewing the product catalog
    When I click on a product titled "MacBook Pro 16-inch"
    Then I should see the product details page
    And the page should display the product name, price, description, and images

  @product-catalog @details
  Scenario: View product reviews
    Given I am on the product details page for "iPhone 15"
    When I scroll to the reviews section
    Then I should see customer reviews and ratings
    And the average rating should be displayed

  @cart @add
  Scenario: Add product to cart
    Given I am on the product details page for "Wireless Mouse"
    When I click the "Add to Cart" button
    Then the product should be added to my cart
    And the cart icon should show "1" item

  @cart @add
  Scenario: Add multiple quantities to cart
    Given I am on the product details page for "USB Cable"
    When I set the quantity to 3
    And I click the "Add to Cart" button
    Then the cart should contain 3 units of "USB Cable"

  @cart @remove
  Scenario: Remove product from cart
    Given I have "Keyboard" in my cart
    When I view my cart
    And I click the remove button for "Keyboard"
    Then "Keyboard" should be removed from my cart
    And the cart should update the total

  @cart @update
  Scenario: Update product quantity in cart
    Given I have "Monitor" in my cart with quantity 1
    When I view my cart
    And I change the quantity to 2
    Then the cart should show 2 units of "Monitor"
    And the subtotal should be updated accordingly

  @cart @update
  Scenario: Decrease product quantity in cart
    Given I have "Headphones" in my cart with quantity 3
    When I view my cart
    And I change the quantity to 1
    Then the cart should show 1 unit of "Headphones"

  @cart @validation
  Scenario: Prevent adding out-of-stock product to cart
    Given I am on the product details page for an out-of-stock item
    Then the "Add to Cart" button should be disabled
    And I should see an "Out of Stock" message

  @cart @validation
  Scenario: Validate maximum quantity limit
    Given I am on the product details page for "Limited Edition Item"
    When I try to set the quantity to 100
    Then I should see an error message about maximum quantity
    And the quantity should remain at the maximum allowed value

  @cart @total
  Scenario: Calculate cart total correctly
    Given I have the following products in my cart:
      | Product  | Quantity | Price  |
      | Laptop   | 1        | 999.99 |
      | Mouse    | 2        | 29.99  |
      | Keyboard | 1        | 79.99  |
    When I view my cart
    Then the subtotal should be 1139.96
    And the total should include applicable taxes

  @cart @coupon
  Scenario: Apply discount coupon to cart
    Given I have products totaling 200 in my cart
    When I enter the coupon code "SAVE20"
    And I click "Apply Coupon"
    Then I should see a discount of 40 applied
    And the new total should be 160

  @cart @empty
  Scenario: View empty cart
    Given I have no items in my cart
    When I view my cart
    Then I should see an "Your cart is empty" message
    And I should see a "Continue Shopping" button

  @checkout @guest
  Scenario: Proceed to checkout as guest
    Given I have items in my cart
    And I am not logged in
    When I click "Proceed to Checkout"
    Then I should be offered the option to checkout as guest
    And I should be able to continue without creating an account

  @checkout @shipping
  Scenario: Enter shipping address
    Given I am on the checkout page
    When I fill in the shipping address form with valid data
    And I click "Continue to Payment"
    Then my shipping address should be saved
    And I should proceed to the payment step

  @checkout @shipping
  Scenario: Validate required shipping fields
    Given I am on the checkout page
    When I try to continue without filling required fields
    Then I should see validation errors for all required fields
    And I should not proceed to the next step

  @checkout @billing
  Scenario: Use same address for billing and shipping
    Given I have entered my shipping address
    When I check "Use shipping address for billing"
    Then the billing address fields should be pre-filled
    And I should be able to proceed to payment

  @checkout @payment
  Scenario: Select payment method
    Given I am on the payment step of checkout
    When I select "Credit Card" as the payment method
    Then I should see the credit card form
    And I should be able to enter card details

  @checkout @payment
  Scenario: Complete order with credit card
    Given I have entered shipping and billing information
    And I am on the payment step
    When I enter valid credit card details
    And I click "Place Order"
    Then my order should be processed successfully
    And I should see an order confirmation page

  @checkout @payment
  Scenario: Select PayPal as payment method
    Given I am on the payment step of checkout
    When I select "PayPal" as the payment method
    Then I should be redirected to PayPal's login page

  @checkout @review
  Scenario: Review order before placing
    Given I have completed all checkout steps
    When I am on the order review page
    Then I should see a summary of my order
    And I should see the shipping address, billing address, and payment method
    And I should see the order total

  @checkout @confirmation
  Scenario: Receive order confirmation
    Given I have successfully placed an order
    Then I should see an order confirmation number
    And I should receive a confirmation email
    And the order should appear in my order history

  @user @registration
  Scenario: Register new user account
    Given I am on the registration page
    When I fill in all required registration fields
    And I click "Create Account"
    Then my account should be created successfully
    And I should be logged in automatically

  @user @registration @validation
  Scenario: Validate email format during registration
    Given I am on the registration page
    When I enter an invalid email format
    And I try to submit the registration form
    Then I should see an email validation error
    And the account should not be created

  @user @registration @validation
  Scenario: Prevent duplicate email registration
    Given a user with email "test@example.com" already exists
    When I try to register with email "test@example.com"
    Then I should see an error message about duplicate email
    And the registration should not proceed

  @user @login
  Scenario: Login with valid credentials
    Given I am on the login page
    When I enter valid email and password
    And I click "Login"
    Then I should be logged in successfully
    And I should be redirected to my account dashboard

  @user @login
  Scenario: Login fails with invalid credentials
    Given I am on the login page
    When I enter invalid email or password
    And I click "Login"
    Then I should see an error message
    And I should remain on the login page

  @user @login
  Scenario: Remember me functionality
    Given I am on the login page
    When I check the "Remember Me" option
    And I login with valid credentials
    Then I should remain logged in after closing the browser

  @user @logout
  Scenario: Logout from account
    Given I am logged in
    When I click the logout button
    Then I should be logged out successfully
    And I should be redirected to the home page

  @user @profile
  Scenario: Update user profile information
    Given I am logged in
    And I am on my profile page
    When I update my name and phone number
    And I click "Save Changes"
    Then my profile should be updated successfully
    And I should see a success message

  @user @profile
  Scenario: Change password
    Given I am logged in
    And I am on the change password page
    When I enter my current password
    And I enter a new password
    And I confirm the new password
    And I click "Update Password"
    Then my password should be changed successfully

  @user @orders
  Scenario: View order history
    Given I am logged in
    And I have placed orders in the past
    When I navigate to my order history
    Then I should see a list of all my previous orders
    And each order should display order number, date, total, and status

  @user @orders
  Scenario: View order details
    Given I am viewing my order history
    When I click on a specific order
    Then I should see the complete order details
    And I should see the list of products, quantities, and prices

  @user @orders
  Scenario: Track order shipment
    Given I have an order that has been shipped
    When I view the order details
    Then I should see the tracking number
    And I should be able to track the shipment status

  @user @wishlist
  Scenario: Add product to wishlist
    Given I am logged in
    And I am viewing a product
    When I click the "Add to Wishlist" button
    Then the product should be added to my wishlist
    And I should see a confirmation message

  @user @wishlist
  Scenario: Remove product from wishlist
    Given I have products in my wishlist
    When I view my wishlist
    And I click remove on a product
    Then the product should be removed from my wishlist

  @admin @inventory
  Scenario: Admin adds new product
    Given I am logged in as an admin
    And I am on the product management page
    When I click "Add New Product"
    And I fill in all product details
    And I click "Save Product"
    Then the new product should be added to the catalog

  @admin @inventory
  Scenario: Admin updates product stock
    Given I am logged in as an admin
    And I am viewing a product in the admin panel
    When I update the stock quantity to 50
    And I save the changes
    Then the product stock should be updated to 50

  @admin @inventory
  Scenario: Admin deactivates product
    Given I am logged in as an admin
    And I am viewing an active product
    When I change the product status to "Inactive"
    And I save the changes
    Then the product should not be visible to customers

  @admin @reports
  Scenario: Generate sales report
    Given I am logged in as an admin
    And I am on the reports page
    When I select "Sales Report"
    And I choose a date range
    And I click "Generate Report"
    Then I should see a detailed sales report for the selected period

  @admin @users
  Scenario: Admin views user list
    Given I am logged in as an admin
    And I navigate to the user management page
    Then I should see a list of all registered users
    And I should be able to filter and search users

  @performance @search
  Scenario: Search response time under load
    Given 1000 concurrent users are on the platform
    When they all perform product searches simultaneously
    Then the average response time should be under 2 seconds
    And no errors should occur

  @smoke @critical
  Scenario Outline: Login with different user roles
    Given I am on the login page
    When I login with email "<email>" and password "<password>"
    Then I should be logged in as "<role>"
    And I should see the "<dashboard>" dashboard

    Examples:
      | email                | password  | role     | dashboard        |
      | customer@example.com | pass123   | customer | My Account       |
      | admin@example.com    | admin123  | admin    | Admin Panel      |
      | vendor@example.com   | vendor123 | vendor   | Vendor Dashboard |

  @navigation
  Scenario: Navigate through product categories
    Given I am on the home page
    When I click on the "Electronics" menu
    Then I should see subcategories displayed
    And I should be able to navigate to any subcategory

  @newsletter
  Scenario: Subscribe to newsletter
    Given I am on the home page
    When I enter my email in the newsletter subscription field
    And I click "Subscribe"
    Then I should see a success message
    And I should receive a welcome email
