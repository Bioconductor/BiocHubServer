#!/usr/bin/env ruby
require 'sequel'
require 'fileutils'

## WARNING: THIS DELETES ALL DATA AND RE-CREATES (empty) TABLES!

if ENV['AHS_DATABASE_TYPE'] == 'mysql'
    _DB = Sequel.connect('mysql://ahuser:password@localhost/ahtest') 
    _DB.run "drop database if exists ahtest;"
    _DB.run "create database ahtest;"
    _DB.run "use ahtest;"
elsif ENV['AHS_DATABASE_TYPE'] == 'sqlite'
    dbfile = "#{File.dirname(__FILE__)}/ahtest.sqlite3"
    if File.exists? dbfile
        FileUtils.rm dbfile
    end
    #DB = Sequel.sqlite(dbfile) 
end

require_relative './db_init'


# FIXME - add null/not null, unique etc., constraints throughout

DB.create_table! :resources do
    primary_key :id
    String :ah_id, {:null => false, :unique => true}

    String :title
    String :dataprovider
    String :species
    Integer :taxonomyid
    String :genome
    String :description
    TrueClass :coordinate_1_based
    String :maintainer
    Integer :status_id
    Integer :location_prefix_id
    Integer :recipe_id
    String :rdataversion
    Date :rdatadateadded # FIXME add index here!

 end

# add users table, info about who uploaded what and when,
#... permissions.

DB.create_table! :rdatapaths do
    primary_key :id
    String :rdatapath
    String :rdataclass
    Integer :rdatasize
    String :rdatamd5
    Date :rdatalastmodifieddate
    foreign_key :resource_id, :resources
end

DB.create_table! :input_sources do
    primary_key :id
    String :sourcefile
    String :sourcesize # integer?
    String :sourceurl
    String :sourceversion
    String :sourcemd5
    Date :sourcelastmodifieddate
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
end

DB.create_table! :statuses do
    primary_key :id
    String :status
end

DB[:statuses].insert(:status => "Unreviewed")
DB[:statuses].insert(:status => "Public")
DB[:statuses].insert(:status => "Private")


DB.create_table! :location_prefixes do
    primary_key :id
    String :location_prefix
end