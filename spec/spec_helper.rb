# frozen_string_literal: true

if RUBY_ENGINE == "ruby" && RUBY_VERSION.start_with?("3.3.") && (ARGV.none? || ARGV == ["spec"] || ARGV == ["spec/"])
  begin
    require "simplecov"

    SimpleCov.start do
      enable_coverage :branch
      minimum_coverage line: 100, branch: 100
    end
  rescue LoadError
  end
end

require "diana"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
