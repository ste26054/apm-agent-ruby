# frozen_string_literal: true

require 'json'
require 'timeout'

class FakeServer
  class << self
    def requests
      @requests ||= []
    end

    def clear!
      @requests = []
    end

    def call(env)
      request = Rack::Request.new(env)
      requests << JSON.parse(request.body.read)

      [200, { 'Content-Type' => 'application/json' }, ['ok']]
    end
  end
end

RSpec.configure do |config|
  config.before :each, :with_fake_server do
    puts "\n"
    puts 'stuuuuuub' + ('v' * 80)
    @request_stub =
      WebMock.stub_request(:any, /.*/).to_rack(FakeServer)
    FakeServer.clear!
  end

  config.after :each, :with_fake_server do
    puts 'after'
    pp @request_stub.inspect
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def wait_for_requests_to_finish(request_count)
    Timeout.timeout(5) do
      loop do
        missing = request_count - FakeServer.requests.length
        next if missing > 0

        if missing < 0
          puts format(
            'Expected %d requests. Got %d',
            request_count,
            FakeServer.requests.length
          )
        end

        break true
      end
    end
  rescue Timeout::Error
    puts format('Died waiting for %d requests', request_count)
    puts "--- Received: ---\n#{FakeServer.requests.inspect}"
    raise
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
end
