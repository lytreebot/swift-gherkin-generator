@missing-steps
Feature: Structurally Invalid Feature
  As a validator test
  I want to catch structural issues
  So that features are well-formed

  Scenario: Missing Given step
    When I perform an action
    Then something happens

  Scenario: Missing When step
    Given a precondition
    Then something happens

  Scenario: Missing Then step
    Given a precondition
    When I perform an action

  Scenario: Empty scenario with no steps

  Scenario: Only And steps without primary keyword
    And something
    And something else

  Scenario Outline: Missing examples
    Given a "<param>"
    When I do something
    Then the result is "<result>"

  Scenario Outline: Empty examples table
    Given a "<value>"
    When I process it
    Then the output is "<output>"

    Examples:
      | value | output |
