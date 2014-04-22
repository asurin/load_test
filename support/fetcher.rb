class Fetcher
  include Celluloid

  def initialize(sync_method, serial_number, target)
    @sync_method = sync_method
    @serial_number = serial_number
    @target = target
    @run = true
  end

  def perform_fetches
    data = { serial_number: @serial_number }
    while @run do
      sleep 0.1 # Allow interrupts
      start_time = Time.now
      begin
        Mechanize.new.get(@target)
        data[:result] = 'Success'
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