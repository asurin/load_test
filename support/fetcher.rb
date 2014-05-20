require 'celluloid'
require 'uri'

class Fetcher
  include Celluloid

  def initialize(sync_method, serial_number, host, crawl, verification_phrase = nil)
    @sync_method = sync_method
    @serial_number = serial_number
    @target = host
    @pages_to_crawl = [ '/' ]
    @crawl = crawl
    @datapoint_queue = Array.new
    @agent = Mechanize.new
    @agent.user_agent = 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)'
    @agent.read_timeout = 5
    @verification_phrase = verification_phrase
    @run = true
  end

  def perform_fetches
    while @run do
      #sleep 0.00001
      begin
        data = { serial_number: @serial_number }
        start_time = Time.now
        index = rand(@pages_to_crawl.length)
        page_to_get = @pages_to_crawl[index]
        @pages_to_crawl.delete_at(index)
        data[:page_url] = "#{@target}#{page_to_get}"
        page = @agent.get(data[:page_url])
        data[:result] = (!@verification_phrase.nil? && !page.body.include?(@verification_phrase))? "Content Error (#{page.code})" : "Success (#{page.code})"
        if @pages_to_crawl.size < 1000 && @crawl
          @pages_to_crawl = @pages_to_crawl + page.links.select{|link| !link.uri.nil? && (link.uri.host.nil? || link.uri.host == URI.parse(@target).host) && link.href.start_with?('/') }.map{ |link| link.href }
        else
          @pages_to_crawl = [ '/' ] unless @crawl
        end
      rescue Timeout::Error => e
        data[:result] = 'Timeout Error'
      rescue Mechanize::ChunkedTerminationError => e
        data[:result] = "Chunk Error #{e.response_code.to_i}"
      rescue Mechanize::ResponseCodeError => e
        data[:result] = "HTTP #{e.response_code.to_i}"
      rescue SocketError
        data[:result] = 'Link Error'
      rescue NoMethodError => e
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