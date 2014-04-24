#!/usr/bin/env ruby
require 'yaml'
require './support/engine.rb'

engine = Engine.new(YAML::load_file(File.join(__dir__, 'config.yml')))
trap('SIGINT') { engine.destroy }
engine.run
engine.destroy