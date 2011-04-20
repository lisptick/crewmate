@javascript
Feature: Show more comment on activity pages

  Background:
  Given a project with users @balint, @pablo, @charles, @jordi and @james
  Given I am logged in as @charles
  And I am in the project called "Teambox" the following comments:
    | body                                        | conversation                   |
    | I read a lot of good stuff about it         | What do you think about redis  |
    | Should we do A/B testing?                   | Should we use A/B testing      |
    | Its pointless, memcached work.              | What do you think about redis  |
    | Mew, just put more money on google ads      | Should we use A/B testing      |
    | Still, we should look at the possibility.   | What do you think about redis  |
    | Okay, let's try it. Vanity, A/Bingo?        | Should we use A/B testing      |
    | The collection thing is interresting.       | What do you think about redis  |
    | Let's go with bingo, look simpler           | Should we use A/B testing      |
    | I did benchmark vs memcached, quite similar.| What do you think about redis  |
    | Its almost done.                            | Should we use A/B testing      |
  And 10 comments are created in the project "Teambox"

  Scenario: Show more with mixed threads
    When I go to the projects page
    And I follow "Show more"
    Then I should see "What do you think about redis" only once
    And I should see "Should we use A/B testing" only once

  Scenario: Show more with new comment in visible thread
    When I go to the projects page
    And 10 comments are created in the project "Teambox"
    And I follow "Show more"
    Then I should see "What do you think about redis" only once
    And I should see "Should we use A/B testing" only once

  Scenario: Activities are not swallowed by a thread
    Given I started a simple conversation in the "Teambox" project
    And   I started a conversation named "Very important stuff" in the "Teambox" project
    And   I started a conversation named "Really critical things" in the "Teambox" project
    And   I wait for 1 second
    And   I add a comment to the last conversation in the "Teambox" project
    And   I wait for 2 seconds
    When  I create 24 pages in the "Teambox" project
    And   I go to the projects page
    And   I follow "Show more"
    And   I wait for 3 seconds
    Then show me the page
    Then  I should see "Very important stuff"
    And   I should see "Really critical things"

