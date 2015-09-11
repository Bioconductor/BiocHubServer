#!/usr/bin/env ruby
require 'sequel'
require 'yaml'


unless defined? LOGGING_DB
    basedir = File.dirname(__FILE__)
    config = YAML.load_file("#{basedir}/config.yml")
    if config.has_key? "logging_url"
      LOGGING_DB = Sequel.connect config["logging_url"]
    else
      LOGGING_DB = Sequel.sqlite
    end
end
