#!/usr/bin/env ruby
require 'sequel'
require 'fileutils'
require 'yaml'
require 'time'
require 'mysql2'

## WARNING: THIS DELETES ALL DATA AND RE-CREATES (empty) TABLES!

## WARNING2: IF YOU REALLY WANT TO START OVER, BE SURE YOU 
## RUN MIGRATIONS AS WELL AFTER RUNNING THIS FILE IN
## ORDER TO GET ALL SCHEMA CHANGES.
## (see migrations/001_add_test.rb for instructions)


basedir = File.dirname(__FILE__)
config = YAML.load_file("#{basedir}/config.yml")

if config['dbtype'] == 'mysql'
    dbname = config['mysql_url'].split('/').last
    _DB = Sequel.connect(config['mysql_url']) 
    _DB.run "drop database if exists #{dbname};"
    _DB.run "create database #{dbname};"
    _DB.run "use #{dbname};"
elsif config['dbtype'] == 'sqlite'
    dbfile = "#{basedir}/#{config['dbname']}.sqlite3"
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
    Date :rdatadateremoved

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
    String :tag, :size => 400
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

DB.create_table! :timestamp do
    DateTime :timestamp
end

DB[:timestamp].insert(:timestamp => Time.now)

# triggers
for table in DB.tables 
    next if table == :timestamp
    for op in ['insert', 'update', 'delete']
        trigger = nil
        if config['dbtype'] == 'sqlite'
            trigger=<<-"EOT"
                 create trigger #{table}_#{op} after #{op} on #{table} 
                   begin
                   update timestamp set timestamp 
                     = datetime('now', 'localtime');
                   end;
            EOT
        elsif config['dbtype'] == 'mysql'
            trigger=<<-"EOT"
                create trigger #{table}_#{op} after #{op}
                  on #{table} for each row 
                    update timestamp set timestamp = current_timestamp();
            EOT
        end
        DB.run trigger
    end
end


