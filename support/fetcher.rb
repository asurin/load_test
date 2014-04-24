require 'celluloid'

class Fetcher
  include Celluloid

  def initialize(sync_method, serial_number, target)
    @sync_method = sync_method
    @serial_number = serial_number
    @target = target
    @agent = Mechanize.new
    @run = true
  end

  def perform_fetches
    data = { serial_number: @serial_number }
    while @run do
      sleep 0.0001
      start_time = Time.now
      begin
        page = @agent.get(@target)
        data[:result] = "Success (#{page.code})"
      rescue Mechanize::ResponseCodeError => e
        data[:result] = "HTTP #{e.response_code.to_i}"
      rescue SocketError
        data[:result] = 'Link Error'
      rescue NoMethodError
        data[:result] = 'Script Error'
      rescue Net::HTTP::Persistent::Error
        data[:result] = 'Connection Reset'
      end
      data[:run_time] = Time.now - start_time
      @sync_method.call(data)
    end
  end

  def stop_working
    @run = false
  end
end