# frozen_string_literal: true

source "https://rubygems.org"

gem "rake", "~> 13.0"
gem "rspec", "~> 3.0"
gem "standard", "~> 1.3"
gem "rubocop-rspec", "~> 3.2"
gem "rubocop-rake", "~> 0.6"
gem "simplecov"

gemspec name: "diana", path: "../"
