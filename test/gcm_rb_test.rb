# frozen_string_literal: true

require "test_helper"

class GcmRbTest < Minitest::Test
  def test_version
    refute_nil GcmRb::VERSION
  end
end
