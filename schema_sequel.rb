require 'sequel'





DB = Sequel.connect('mysql://ahuser:password@localhost/ahtest')

def defd? (table)
    begin
        tbl = DB.schema(table)
        return true
    rescue
        return false
    end
end


DB.drop_table :metadata if defd? :metadata

DB.create_table :metadata do
  primary_key :id
  String :dataprovider
  String :species
  String :taxonomyid #integer
  String :genome
  String :description
  TrueClass :coordinate_1_based
  String :maintainer
#  String :name, :unique => true, :null => false
#  TrueClass :active, :default => true
#  foreign_key :category_id, :categories
#  DateTime :created_at

#  index :created_at
end

