
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
    one_to_many :tags
    one_to_many :biocversions
    many_to_one :recipe
    many_to_one :status
    many_to_one :location_prefix




    def after_save
        if self.ah_id =~ /==$/
            self.update(:ah_id=>"AH#{self.id}")
        end

    end

end

class Rdatapath < Sequel::Model
    many_to_one :resource
end

class InputSource < Sequel::Model
    many_to_one :resource
end

class Tag < Sequel::Model
    many_to_one :resource
end

class Biocversion < Sequel::Model
    many_to_one :resource
end

class Recipe < Sequel::Model
    one_to_many :resource
end

class Status < Sequel::Model
    one_to_many :resource
end

class LocationPrefix < Sequel::Model
    one_to_many :resource
end