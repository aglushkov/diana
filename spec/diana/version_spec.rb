# frozen_string_literal: true

RSpec.describe "Diana::VERSION" do
  it "has a semantic version format" do
    expect(Diana::VERSION).to match(/\d+\.\d+\.\d+/)
  end
end
