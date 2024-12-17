# frozen_string_literal: true

module Diana
  # Returns the version of the Diana gem.
  #
  # @return [String] The version of the gem in Semantic Versioning (SemVer) format.
  #
  VERSION = File.read(File.join(File.dirname(__FILE__), "../../VERSION")).strip
end
