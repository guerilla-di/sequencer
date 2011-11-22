# -*- ruby -*-
require 'rubygems'
require 'jeweler'
require File.dirname(__FILE__) + "/lib/sequencer"

Jeweler::Tasks.new do |gem|
  gem.version = Sequencer::VERSION
  gem.name = "sequencer"
  gem.summary = "Image sequence sorting, scanning and manipulation"
  gem.email = "me@julik.nl"
  gem.homepage = "http://guerilla-di.org/sequencer"
  gem.authors = ["Julik Tarkhanov"]
  gem.license = 'MIT'
  gem.executables = %w( rseqls rseqpad rseqrename )
end

Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
desc "Run all tests"
Rake::TestTask.new("test") do |t|
  t.libs << "test"
  t.pattern = 'test/**/test_*.rb'
  t.verbose = true
end