@edge @unicode @special-chars
Feature: Edge Cases and Special Characters
  As a parser developer
  I want to handle unusual but valid Gherkin
  So that the parser is robust

  Background:
    Given the system supports UTF-8 encoding

  Scenario: Unicode characters in step text
    Given a user named "José García-López"
    And an address "Königstraße 42, München"
    When I save the profile with notes "Привет мир — こんにちは"
    Then the data is stored correctly

  Scenario: Emojis in descriptions
    Given a product "🎧 Wireless Headphones" in the catalog
    And a rating of "⭐⭐⭐⭐⭐"
    When I add a review "Great sound! 🔊👍"
    Then the review appears with emojis intact

  Scenario: Special characters in data table
    Given the following user data:
      | name            | email               | notes                    |
      | O'Brien         | o'brien@test.com    | Single quote in name     |
      | "Quoted" Name   | quoted@test.com     | Quotes in name           |
      | Müller & Söhne  | muller@test.de      | Ampersand and umlauts    |
      | Line\nBreak     | break@test.com      | Escaped newline          |
    When I import the data
    Then all 4 records are created

  Scenario: Empty and whitespace values in data table
    Given a configuration table:
      | key       | value   |
      | host      | db.local |
      | port      | 5432    |
      | password  |         |
      | namespace |         |
    When I load the configuration
    Then 2 keys have empty values

  Scenario: Doc string with special content
    Given an API returns the following XML:
      """xml
      <?xml version="1.0" encoding="UTF-8"?>
      <response status="ok">
        <message>Données récupérées — 日本語テスト</message>
        <items count="3">
          <item id="1" name="Crème brûlée" price="8.50"/>
          <item id="2" name="Ñoquis" price="12.00"/>
          <item id="3" name="Döner" price="7.50"/>
        </items>
      </response>
      """
    When I parse the response
    Then I get 3 items

  Scenario: Very long step text
    Given a product with the description "This is an extremely long product description that spans well beyond the typical length one might expect in a normal Gherkin step, specifically designed to test how the parser handles very long lines without breaking or truncating the content in any way"
    When I save the product
    Then the full description is preserved

  Scenario: Steps using the star keyword
    * the system is ready
    * I perform the action
    * the result is recorded
    * no errors occurred

  Scenario: Tags with special characters
    Given a scenario exists
    When I process it
    Then it completes

  Scenario: Multiple consecutive And/But steps
    Given a base condition
    And a second condition
    And a third condition
    And a fourth condition
    When an action occurs
    Then a result happens
    But not this
    But not that either
    And also this is true
