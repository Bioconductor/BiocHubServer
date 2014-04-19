require 'sequel'

## WARNING: THIS DELETES ALL DATA AND RE-CREATES (empty) TABLES!


#DB = Sequel.connect('mysql://ahuser:password@localhost/ahtest') # mysql

# or

DB = Sequel.sqlite("#{File.dirname(__FILE__)}/ahtest.sqlite3") # sqlite


# FIXME - add null/not null, unique etc., constraints throughout

DB.create_table! :metadata do
    primary_key :id
    String :dataprovider
    String :species
    Integer :taxonomyid
    String :genome
    String :description
    TrueClass :coordinate_1_based
    String :maintainer
end

DB.create_table! :rdatapath do
    primary_key :id
    String :rdatapath
    String :rdataclass
    foreign_key :metadata_id, :metadata
end

DB.create_table! :input_source do
    primary_key :id
    String :sourcefile
    String :sourcesize # integer?
    String :sourceurl
    String :sourceversion
    foreign_key :metadata_id, :metadata
end

DB.create_table! :version do
    primary_key :id
    String :rdataversion
    Date :rdatadateadded
    foreign_key :metadata_id, :metadata
end

DB.create_table! :tags do
    primary_key :id
    String :tag
    foreign_key :metadata_id, :metadata
end

DB.create_table! :biocversion do
    primary_key :id
    String :biocversion
    foreign_key :metadata_id, :metadata
end

DB.create_table! :recipe do
    primary_key :id
    String :recipe
    String :recipeargs
    foreign_key :metadata_id, :metadata
end

# maybe don't need this because of migrations?
DB.create_table! :schema_metadata do
    primary_key :id
    String :schema_data
    String :schema_version # integer?
    String :client_version
    String :change_notes
end