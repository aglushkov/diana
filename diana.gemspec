# frozen_string_literal: true

require_relative "lib/diana/version"

Gem::Specification.new do |spec|
  spec.name = "diana"
  spec.version = Diana::VERSION
  spec.authors = ["Andrey Glushkov"]
  spec.email = ["aglushkov@shakuro.com"]

  spec.summary = "Lazy Dependency Injection DSL"
  spec.description = <<~DESC
    Lazy dependency injection /
    Simple and clear DSL /
    No magic /
    No dependencies
  DESC

  spec.homepage = "https://github.com/aglushkov/diana"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage + "/blob/master/CHANGELOG.md"

  spec.files = Dir["lib/**/*.rb"] << "VERSION" << "README.md"
  spec.require_paths = ["lib"]
end