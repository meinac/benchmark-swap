# frozen_string_literal: true

require "stringio"
require "benchmark/swap"

RSpec.configure do |config|
  config.expect_with(:rspec) { |expectations| expectations.syntax = :expect }
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand(config.seed)
end

# Runs the block with $stdout captured, and returns what was written.
def capture_stdout
  original = $stdout
  $stdout = StringIO.new
  yield
  $stdout.string
ensure
  $stdout = original
end
