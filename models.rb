
# to play in the sequel console, do this:
# # sequel sqlite://`pwd`/ahtest.sqlite3


require 'sequel'
require 'securerandom'

class Resource < Sequel::Model

    def before_save
        unless self.ah_id =~ /^AH/
            self.ah_id = SecureRandom.base64        
        end
    end


    one_to_many :rdatapaths
    one_to_many :input_sources
    one_to_many :versions
    one_to_many :tags
    one_to_many :biocversions
    one_to_many :recipes
    one_to_one  :status
    one_to_one  :location_prefix




    def after_save
        if self.ah_id =~ /==$/
            self.update(:ah_id=>"AH_#{self.id}")
        end

    end

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

class Status < Sequel::Model
    one_to_one :resource
end

class LocationPrefix < Sequel::Model
    one_to_one :resource
end