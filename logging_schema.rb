#!/usr/bin/env ruby

require 'sequel'
require 'yaml'

basedir = File.dirname(__FILE__)
config = YAML.load_file("#{basedir}/config.yml")

dbname = config['logging_url'].split('/').last
_DB0 = Sequel.connect config['logging_url']
_DB0.run "drop database if exists #{dbname};"
_DB0.run "create database #{dbname};"
_DB0.run "use #{dbname};"


require_relative './logging_init'


LOGGING_DB.create_table! :s3_log_files do
    primary_key :id
    String :filename, {:null => false, :unique => true}
    index :filename, :unique=>true
end

# FIXME add appropriate indexes

LOGGING_DB.create_table! :log_entries do
    primary_key :id
    DateTime :timestamp
    String :remote_ip
    String :url
    String :request_uri
    String :http_status
    String :s3_error_code
    TrueClass :is_s3, {:null => false}
    Integer :bytes_sent
    Integer :object_size
    Integer :total_time
    Integer :turn_around_time
    String :referrer
    String :user_agent
    String :s3_version_id
    Integer :s3_log_file_id
    Integer :id_fetched
    Integer :resource_fetched
end
