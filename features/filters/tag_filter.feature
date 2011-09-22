@javascript
Feature: tags are multiselectable on the homepage, OR'd with aspects
	In order to choose what sorts of conversations i see in my stream
	As a diaspora user
	I want to use the sidebar to select hashtags that will be shown in the main stream

	Background:
	  Given a user with username "alice"
      And a user with username "bob"
      And a user with username "bob" is connected with "alice"
      # TODO(dk): and bob follows then and now
      And "bob@bob.bob" has a public post with text "That is what I was doing #then"
      And "bob@bob.bob" has a public post with text "This is what I'm doing #now"
      And I sign in as "alice@alice.alice"
      And I am on the stream page

      Scenario: unfiltered (default) shows all
      	Then I should see "That is what I was doing #then"
      	And I should see "This is what I'm doing #now"

      Scenario: filter to one hash tag by deselecting the other
      	When I deselect "#then" # TODO(dk): in the hashtag navigation menu
      	Then I should see "This is what I'm doing #now"
      	And I should not see "That is what I was doing #then"

	  Scenario: filter to one hash tag by deselecting the other
      	When I follow "#then" # TODO(dk): in the hashtag navigation menu
      	Then I should see "That is what I was doing #then"
      	And I should not see "This is what I'm doing #now"

      # TODO(dk): Scenario: filter to one aspect by deselecting the other

      # TODO(dk): Scenario: filter to the other by clicking on it