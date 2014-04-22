Load Test
=========

Multi-threaded load tester

  - Uses JRuby in Ruby 2.0 compatibility mode (Tested on 1.7.10)
  - Should work under Rubinius and MRI, but will suffer significant performance issues on the latter
  - Set confiruation options in config.yml
  - run load_test.rb to run
  - Generates approximately 0.5m requests per hour