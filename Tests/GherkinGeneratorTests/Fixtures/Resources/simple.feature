Feature: User Authentication
  As a registered user
  I want to log into my account
  So that I can access my personal dashboard

  Scenario: Successful login with valid credentials
    Given a registered user with email "alice@example.com"
    When the user submits valid credentials
    Then the user is redirected to the dashboard
    And a welcome message is displayed
