require 'celluloid'

class Fetcher
  include Celluloid

  def initialize(sync_method, serial_number, target, verification_phrase = nil)
    @sync_method = sync_method
    @serial_number = serial_number
    @target = target
    @agent = Mechanize.new
    @agent.user_agent = 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)'
    @verification_phrase = verification_phrase
    @run = true
  end

  def perform_fetches
    data = { serial_number: @serial_number }
    while @run do
      sleep 0.0001
      start_time = Time.now
      begin
        page = @agent.get(@target)
        data[:result] = (!@verification_phrase.nil? && !page.body.include?(@verification_phrase)) ? "Content Error (#{page.code})" : "Success (#{page.code})"
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