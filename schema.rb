require 'rubygems'
require 'data_mapper'
require 'dm-migrations'

  
url = "sqlite://#{Dir.pwd}/ahs.sqlite3"  
url = "mysql://root@localhost/AnnotationHubMetadata"

conn = DataMapper.setup(:default, url)

class Metadata
  include DataMapper::Resource

  # has n, :versions
  # has n, :r_data_paths
  # has n, :input_sources
  # has n, :tags
  # has n, :bioc_versions
  # has n, :recipes


  property :_id,         Serial    # An auto-increment integer key
  property :dataprovider, Text
  property :title,      Text
  property :species, Text
  property :taxonomyid, Integer
  property :genome,  Text
  property :description, Text
  property :coordinate_1_based, Integer #Boolean
  property :maintainer, Text
end

DataMapper.finalize


__END__

class Version
    include DataMapper::Resource

    belongs_to :metadata

    property :id, Serial
    property :rdataversion, Text
    property :rdatadateadded, DateTime 
end

class RDataPath
    include DataMapper::Resource 

    belongs_to :metadata

    property :id, Serial
    property :rdatapath, Text
    property :rdataclass, Text
end

class InputSource
    include DataMapper::Resource

    belongs_to :metadata

    property :id, Serial
    property :sourcefile, Text
    property :sourcesize, Text
    property :sourceurl, Text
    property :sourceversion, Text
end

class Tag
    include DataMapper::Resource

    belongs_to :metadata

    property :id, Serial
    property :tag, Text
end

class BiocVersion
    include DataMapper::Resource

    belongs_to :metadata

    property :id, Serial
    property :biocvesion, Text
end


class Recipe
    include DataMapper::Resource

    belongs_to :metadata

    property :id, Serial
    property :recipe, Text
    property :recipeargs, Text
end


DataMapper.finalize

DataMapper.auto_migrate!

