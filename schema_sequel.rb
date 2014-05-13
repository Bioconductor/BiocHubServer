#!/usr/bin/env ruby
require 'sequel'
require 'fileutils'

## WARNING: THIS DELETES ALL DATA AND RE-CREATES (empty) TABLES!


# mode can be either :sqlite or :mysql

mode = nil
if ENV['AHS_DATABASE_TYPE'].nil? or 
  !(["mysql", "sqlite"].include? ENV['AHS_DATABASE_TYPE'])
    puts "environment variable AHS_DATABASE_TYPE must be set to"
    puts "mysql or sqlite."
    exit
else
    mode = ENV['AHS_DATABASE_TYPE'].to_sym
end



if mode == :mysql
    _DB = Sequel.connect('mysql://ahuser:password@localhost/ahtest') 
    _DB.run "drop database if exists ahtest;"
    _DB.run "create database ahtest;"
    DB = Sequel.connect('mysql://ahuser:password@localhost/ahtest') 
else
    dbfile = "#{File.dirname(__FILE__)}/ahtest.sqlite3"
    if File.exists? dbfile
        FileUtils.rm dbfile
    end
    DB = Sequel.sqlite(dbfile) 
end



# FIXME - add null/not null, unique etc., constraints throughout

DB.create_table! :resources do
    primary_key :id
    String :title
    String :dataprovider
    String :species
    Integer :taxonomyid
    String :genome
    String :description
    TrueClass :coordinate_1_based
    String :maintainer
    Integer :status
    Integer :location_prefix
end

# add users table, info about who uploaded what and when,
#... permissions.

DB.create_table! :rdatapaths do
    primary_key :id
    String :rdatapath
    String :rdataclass
    Integer :rdatasize
    foreign_key :resource_id, :resources
end

DB.create_table! :input_sources do
    primary_key :id
    String :sourcefile
    String :sourcesize # integer?
    String :sourceurl
    String :sourceversion
    foreign_key :resource_id, :resources
end

DB.create_table! :versions do
    primary_key :id
    String :rdataversion
    Date :rdatadateadded # FIXME add index here!
    foreign_key :resource_id, :resources
end

DB.create_table! :tags do
    primary_key :id
    String :tag, :text => true # records in mongo were > 255 chars long; not good for tags!
    foreign_key :resource_id, :resources
end

DB.create_table! :biocversions do
    primary_key :id
    String :biocversion
    foreign_key :resource_id, :resources
end

DB.create_table! :recipes do
    primary_key :id
    String :recipe
    String :package
    String :recipeargs
    foreign_key :resource_id, :resources
end

DB.create_table! :statuses do
    primary_key :id
    String :status
end

DB.create_table! :location_prefixes do
    primary_key :id
    String :location_prefix
end