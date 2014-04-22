#!/usr/bin/env ruby
require 'yaml'
require 'celluloid'
require 'chronic_duration'
require 'mechanize'
require './support/engine.rb'

engine = Engine.new(YAML::load_file(File.join(__dir__, 'config.yml')))
engine.run
engine.destroy