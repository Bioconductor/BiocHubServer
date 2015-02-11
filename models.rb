
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
            errors.add(item, 'cannot be empty') if thing.nil? || 
                (thing.respond_to?(:empty?) && thing.empty?)
        end
    end

    def before_create
        # h = self.to_hash

        # unless Resource.find(h).nil?
        #     return false
        # end
        unless self.ah_id =~ /^AH/
            self.ah_id = SecureRandom.base64        
        end

        true
        super
    end


    def after_create
        super

        if self.record_id.nil?
            self.record_id = self.get_record_id()
        end

        true
    end

    ## to update all record ids do this:
    def self.update_record_ids(force=false)
        x = nil
        if force
            x = Resource.where()
        else
            x = Resource.where(record_id: nil)
        end
        x.each_with_index do |resource, i|
            if i % 1000 == 0
                print "."
            end
            resource.record_id = resource.get_record_id(force)
            resource.save
        end
    end

    def get_record_id(force=false)
        unless force
            unless self.record_id.nil?
                return self.record_id
            end
        end
        max = DB[:resources].max(:record_id)
        return 1 if (max.nil?)
        resources = DB[:resources]
        cands = 
            resources.where(Sequel.negate(ah_id: \
                self.ah_id)).where(taxonomyid: self.taxonomyid,
                genome: self.genome, recipe_id: self.recipe_id)
        for cand in cands
            input_sources = InputSource.where(resource_id: cand[:id])
            if input_sources.count == self.input_sources.count
                if input_sources.map{|i| i.sourceurl} == \
                  self.input_sources.map{|i| i.sourceurl}
                    rdatapaths = Rdatapath.where(resource_id: cand[:id])
                    if rdatapaths.count == self.rdatapaths.count
                        if rdatapaths.map{|i| i.rdataclass} == \
                          self.rdatapaths.map{|i| i.rdataclass}
                            return cand[:record_id]
                        end
                    end
                end
            end
        end
        max = DB[:resources].max(:record_id) # call again just in case
        if (max.nil?) # should not happen
            max = 1
        else
            max += 1
        end
        max
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