require_relative "../lib/log_parser"
require "pathname"
require "open3"

RSpec.configure do |config|
  # This is necessary setting to make multiple assertions per test work
  config.define_derived_metadata do |meta|
    meta[:aggregate_failures] = true
  end
end
