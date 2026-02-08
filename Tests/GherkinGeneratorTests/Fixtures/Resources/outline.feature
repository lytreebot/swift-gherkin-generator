@validation
Feature: Email Address Validation
  As a system administrator
  I want email addresses to be validated on input
  So that only properly formatted addresses are accepted

  Scenario Outline: Validate email format
    Given the user enters the email "<email>"
    When the validation engine processes the input
    Then the result should be "<result>"
    And the error message should be "<message>"

    @valid-emails
    Examples: Valid email addresses
      | email                    | result | message |
      | alice@example.com        | valid  |         |
      | bob.smith@company.co.uk  | valid  |         |
      | user+tag@domain.org      | valid  |         |
      | admin@192.168.1.1        | valid  |         |

    @invalid-emails
    Examples: Invalid email addresses
      | email            | result  | message                    |
      | plainaddress     | invalid | Missing @ symbol           |
      | @missing-local   | invalid | Missing local part         |
      | user@             | invalid | Missing domain             |
      | user@.com        | invalid | Domain starts with dot     |
      | user space@x.com | invalid | Contains illegal character |

  Scenario Outline: Password strength validation
    Given a password "<password>"
    When the strength checker evaluates it
    Then the strength level should be "<level>"

    Examples: Weak passwords
      | password | level  |
      | 123456   | weak   |
      | password | weak   |
      | abcdef   | weak   |

    Examples: Strong passwords
      | password          | level  |
      | C0mpl3x!Pass      | strong |
      | MyS3cur3#Key2025  | strong |
