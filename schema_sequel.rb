#!/usr/bin/env ruby
require 'sequel'
require 'fileutils'

## WARNING: THIS DELETES ALL DATA AND RE-CREATES (empty) TABLES!


# mode can be either :sqlite or :mysql

mode = :mysql


if mode == :mysql
    DB = Sequel.connect('mysql://ahuser:password@localhost/ahtest') 
else
    dbfile = "#{File.dirname(__FILE__)}/ahtest.sqlite3"
    if File.exists? dbfile
        FileUtils.rm dbfile
    end
    DB = Sequel.sqlite(dbfile) 
end


# if mode == :mysql
#     DB.run "drop database if exists ahtest;"
#     DB.run "create database ahtest;"
# end


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
end

DB.create_table! :rdatapaths do
    primary_key :id
    String :rdatapath
    String :rdataclass
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
    Date :rdatadateadded
    foreign_key :resource_id, :resources
end

DB.create_table! :tags do
    primary_key :id
    String :tag, :text => true
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

