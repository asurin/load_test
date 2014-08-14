require './support/fetcher.rb'
require 'chronic_duration'
require 'mechanize'

class Engine

  def initialize(config)
    @data_points = Array.new
    @semaphore = Mutex.new
    @start_time = Time.now
    @config = config
    @run_time = ChronicDuration.parse(@config['duration'])
    @start_time = Time.now
    @workers = Array.new
    @running = true
    @crawl = @config.key?('crawl') ? @config['crawl'] : false
    @log_file = File.open(@config['log_path'], 'w') rescue nil
    print 'Booting...'
    (1..@config['threads']).each { |thread| @workers << Fetcher.new(self.method(:fetcher_callback), thread, @config['host'], @crawl, @config['verification_phrase']) }
    puts "\rLoad Test Engine Initialized - Targeting '#{@config['host']}' @ #{@config['threads']} threads for #{@config['duration']} (#{@run_time}s)"
  end

  def run
    print 'Starting...'
    @workers.each { |thread| thread.async.perform_fetches }
    while (Time.now - @start_time) < @run_time && @running
      print "\r#{formatted_output}"
      sleep 1
    end
  end

  def destroy
    if @running
      print "\r\nTerminating workers..."
      @running = false
      @workers.each_with_index do |worker, index|
        worker.stop_working
        print "\r#{(@workers.length - index) - 1} still running"
      end
      sleep 2
      @workers.each { |worker| worker.terminate }
      @log_file.close
      puts "\r\nDone"
    end
  end

  def fetcher_callback(data)
    @semaphore.synchronize do
      @data_points.push(data)
      log_data_point(data)
    end
  end

  def formatted_output
    output_items = Array.new
    response_values = Hash.new
    average_time = 0.0
    @data_points.each do |data|
      if response_values.has_key? data[:result]
        response_values[data[:result]] += 1
      else
        response_values[data[:result]] = 1
      end
      average_time += data[:run_time].to_f
    end
    average_time = @data_points.length.zero? ? 0 : (average_time.to_f / @data_points.size.to_f)
    responses = response_values.map{|code, count| "#{code}: #{count}"}.join(@config['separator'])
    output_items << "Fetches: #{@data_points.length}"
    output_items << "Average Time: #{average_time.round(4)}s"
    output_items << "Runtime: #{(Time.now - @start_time).round(0)}s"
    output_items << responses
    output_items.join(@config['separator'])
  end

  def log_data_point(data)
    unless @log_file.nil?
      @log_file.write("[#{Time.now.strftime('%Y%m%d%H%M%S%L')}] Request #{@data_points.length} performed by Thread #{data[:serial_number]} targeting #{data[:page_url]} - Returned '#{data[:result]}' in #{data[:run_time]}s\r\n")
      if data.key?(:exception)
        @log_file.write data[:exception].message
        @log_file.write data[:exception].backtrace
      end
    end
  end
end