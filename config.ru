require 'rubygems'
require 'sinatra'

require './app.rb'

set :environment, ENV['RACK_ENV'].to_sym
set :app_file, 'app.rb'
disable :run

log = File.new("logs/sinatra.log", "a")

$stderr.reopen(log)
$stderr.sync = true

run Sinatra::Application