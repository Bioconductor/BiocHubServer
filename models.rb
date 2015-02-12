
# to play in the sequel console, do this:
# # sequel sqlite://`pwd`/annotationhub.sqlite3


require 'sequel'
require 'securerandom'

class Resource < Sequel::Model

    # def  validate
    #     super
    #     required_fields = [:title, :dataprovider, :species, :taxonomyid,
    #         :genome, :description, :coordinate_1_based, :maintainer,
    #         :rdataversion, :rdatadateadded]
    #     for item in required_fields
    #         thing = self.send(item)
    #         errors.add(item, 'cannot be empty') if thing.nil? || 
    #             (thing.respond_to?(:empty?) && thing.empty?)
    #     end
    # end

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
    ## note, it's slow but hopefully we don't have to do this often
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
            record_id = resource.get_record_id(force)
            resource.record_id = record_id
            # puts "record #{resource.id} has record_id #{resource.record_id}"
            resource.save
        end
    end

    def self.get_next_record_id()
        max = Resource.max(:record_id)
        if (max.nil?) 
            max = 1
        else
            max += 1
        end
        max
    end


    def self.set_record_ids()
        resources = DB[:resources]
        h = {}
        count = 1
        Resource.all.each do |resource|
            key = "#{resource.taxonomyid}_#{resource.genome}_#{resource.recipe_id}_"
            key += "#{resource.input_sources.map{|i| i.sourceurl}.join("_")}"
            key += "#{resource.rdatapaths.map{|i| i.rdataclass}.join("_")}"
            h[key] = [] unless h.has_key?(key)
            h[key] << resource.id
        end
        h.each_with_index do |(key, value), index|
            for id in value
                r = Resource[id]
                r.record_id = index
                r.save
            end
        end

    end

    def get_record_id(force=false)
        # @@resources = Resource.all unless(defined?(@@resources)) 
        @@input_sources = InputSource.all unless(defined?(@@input_sources)) 
        @@rdatapaths = Rdatapath.all unless(defined?(@@rdatapaths)) 
        unless force
            unless self.record_id.nil?
                # puts "r0"
                return self.record_id
            end
        end
        resources = DB[:resources]
        max = resources.max(:record_id)
        # puts "r0.5, max is #{max}"
        return 1 if (max.nil?)
        # cands = @@resources.find_all do |i|
        #     i.ah_id != self.ah_id &&
        #     i.taxonomyid == self.taxonomyid &&
        #     i.genome == self.genome &&
        #     i.recipe_id = self.recipe_id
        # end
        cands = \
            resources.where(Sequel.negate(ah_id: \
                self.ah_id)).where(taxonomyid: self.taxonomyid,
                genome: self.genome, recipe_id: self.recipe_id)
        for cand in cands
            #input_sources = InputSource.where(resource_id: cand[:id])
            input_sources = @@input_sources.find_all {|i| i.resource_id == self.id}
            if input_sources.count == self.input_sources.count
                if input_sources.map{|i| i.sourceurl} == \
                  self.input_sources.map{|i| i.sourceurl}
                    #rdatapaths = Rdatapath.where(resource_id: cand[:id])
                    rdatapaths = @@rdatapaths.find_all {|i| i.resource_id == self.id}

                    if rdatapaths.count == self.rdatapaths.count
                        if rdatapaths.map{|i| i.rdataclass} == \
                          self.rdatapaths.map{|i| i.rdataclass}
                            # puts "r1"
                            bingo = Resource[cand[:id]]
                            # puts "bingo: #{bingo.record_id}."
                            if bingo.record_id.nil?
                                bingo.record_id = Resource.get_next_record_id
                                bingo.save
                            end
                            return bingo.record_id
                        end
                    end
                end
            end
        end
        # puts "r2"
        Resource.get_next_record_id
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