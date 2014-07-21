
# to play in the sequel console, do this:
# # sequel sqlite://`pwd`/annotationhub.sqlite3


require 'sequel'
require 'securerandom'

class Resource < Sequel::Model

    def  validate
        super
        required_fields = [:title, :dataprovider, :species, :taxonomyid,
            :genome, :description, :coordinate_1_based, :maintainer,
            :rdataversion, :rdatadateadded]
        for item in required_fields
            pp item
            thing = self.send(item)
            errors.add(item, 'cannot be empty') if !thing || 
                (thing.respond_to? :empty? && thing.empty?)
        end
    end

    def before_create
        h = self.to_hash

        unless Resource.find(h).nil?
            return false
        end
        unless self.ah_id =~ /^AH/
            self.ah_id = SecureRandom.base64        
        end

        true
        super
    end



    one_to_many :rdatapaths
    one_to_many :input_sources
    one_to_many :tags
    one_to_many :biocversions
    many_to_one :recipe
    many_to_one :status
    many_to_one :location_prefix



    ## FIXME - make this a trigger?
    def after_save
        super
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