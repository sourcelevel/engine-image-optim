require 'test_helper'

class Engine::ImageOptimTest < Minitest::Test
  test 'reports images that can be optimized' do
    path = File.expand_path('../fixtures', __dir__)
    io = StringIO.new

    engine = Engine::ImageOptim.new(path, { 'include_paths' => %w(foo.jpg rails-logo.svg) }, io)
    engine.run

    assert_issue io, 'Unoptimized Image', 'foo.jpg'
    refute_issue io, 'rails-logo.svg'
  end

  test 'supports a custom "min_threshold" configuration' do
    path = File.expand_path('../fixtures', __dir__)
    io = StringIO.new

    engine = Engine::ImageOptim.new(path, { 'include_paths' => %w(foo.jpg rails-logo.svg), 'min_threshold' => 0.1 }, io)
    engine.run

    assert_issue io, 'Unoptimized Image', 'foo.jpg'
    assert_issue io, 'Unoptimized Image', 'rails-logo.svg'
  end

  private

  def refute_issue(io, path, msg = nil)
    missing = issues(io.string).none? do |issue|
      issue['location']['path'] == path
    end

    msg = message(msg) { "'#{path}' should not be reported as optimizable." }

    assert missing, msg

  end

  def assert_issue(io, check_name, path, msg = nil)
    found = issues(io.string).any? do |issue|
      issue['check_name'] == check_name && issue['location']['path'] == path
    end

    msg = message(msg) { "Cound not find '#{check_name}' issue on #{io.string}" }

    assert found, msg
  end

  def issues(string)
    string.split("\0").map { |issue| JSON.parse(issue) }
  end
end
