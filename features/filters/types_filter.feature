@javascript
@wip
Feature: filter posts on a user's profile page
	In order to only read about stuff I'm interested
	As a friend of a particular user
	I want to to filter the types of posts I see on their profile

	Background:
	  Given a user with username "alice"
      And a user with username "bob"
      And a user with username "bob" is connected with "alice"
      And "bob@bob.bob" has a public note with text "I can has blogs?"
      And "bob@bob.bob" has a public post with text "This is what I'm doing now"
      And I sign in as "alice@alice.alice"
      And I am on "bob@bob.bob"'s page

      Scenario: unfiltered shows all
      	Then I should see "I can has blogs?"
      	And I should see "This is what I'm doing now"

      Scenario: filter to status messages
      	When I follow "Statuses"
      	Then I should see "This is what I'm doing now"
      	And I should not see "I can has blogs?"

	  Scenario: filter to notes
	  	When I follow "Notes"
      	Then I should see "I can has blogs?"
      	And I should not see "This is what I'm doing now"