#!/usr/bin/env ruby
require 'sequel'
require 'yaml'


unless defined? LOGGING_DB
    basedir = File.dirname(__FILE__)
    config = YAML.load_file("#{basedir}/config.yml")
    LOGGING_DB = Sequel.connect config["logging_url"]
end
