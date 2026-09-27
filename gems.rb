# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :maintenance, optional: true do
	gem "bake-gem-github"
	gem "bake-modernize"
	gem "bake-releases"
	
	gem "agent-context"
	
	gem "utopia-project"
	
	gem "decode"
end

group :test do
	gem "rubocop"
	gem "rubocop-md"
	gem "rubocop-socketry"
	
	gem "bake-test"
	gem "covered"
	gem "sus"
end
