# frozen_string_literal: true

require_relative "lib/socketry/version"

Gem::Specification.new do |spec|
	spec.name = "socketry"
	spec.version = Socketry::VERSION
	
	spec.summary = "Socketry project metadata, agent context, and skills."
	spec.authors = ["Samuel Williams"]
	spec.license = "MIT"
	
	spec.homepage = "https://github.com/socketry/socketry"
	
	spec.metadata = {
		"bug_tracker_uri" => "https://github.com/socketry/socketry/issues",
		"changelog_uri" => "https://github.com/socketry/socketry/blob/main/releases.md",
		"documentation_uri" => "https://socketry.github.io/socketry/",
		"funding_uri" => "https://github.com/sponsors/ioquatix/",
		"source_code_uri" => "https://github.com/socketry/socketry.git",
	}
	
	spec.files = Dir.glob(["{context,lib,skills}/**/*", "*.md"], File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 3.3"
	
	spec.add_dependency "agent-context"
	spec.add_dependency "agent-skills"
end
