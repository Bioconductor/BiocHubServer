
# to play in the sequel console, do this:
# # sequel sqlite://`pwd`/ahtest.sqlite3


require 'sequel'

class Resource < Sequel::Model
    one_to_many :rdatapaths
    one_to_many :input_sources
    one_to_many :versions
    one_to_many :tags
    one_to_many :biocversions
    one_to_many :recipes
end

class Rdatapath < Sequel::Model
    many_to_one :resource
end

class InputSource < Sequel::Model
    many_to_one :resource
end

class Version < Sequel::Model
    many_to_one :resource
end

class Tag < Sequel::Model
    many_to_one :resource
end

class Biocversion < Sequel::Model
    many_to_one :resource
end

class Recipe < Sequel::Model
    many_to_one :resource
end

