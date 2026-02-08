Feature: Invalid Syntax Examples

  This file contains deliberate syntax errors for testing error handling.

  Scenario Missing colon after keyword
    Given a step
    When another step
    Then a result

  Scenario: Valid scenario followed by orphan steps
    Given something

  Given orphan step without scenario
  When another orphan step

  Scenario: Unclosed data table
    Given the following data:
      | col1 | col2
      | val1 | val2 |

  Scenario: Malformed tags
    Given something
    When something else
    Then result

  Feature: Duplicate feature keyword
    This should not appear — only one Feature per file.

  Scenario: Steps after examples in outline
    Given a "<value>"

    Examples:
      | value |
      | test  |

    Then this step is misplaced
