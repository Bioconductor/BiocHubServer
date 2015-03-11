
# to play in the sequel console, do this:
# # sequel sqlite://`pwd`/annotationhub.sqlite3


require 'sequel'
require 'securerandom'

class Resource < Sequel::Model

    def  validate
        super
        required_fields = [:title, :dataprovider, 
            :description, :coordinate_1_based, :maintainer,
            :rdatadateadded, :preparerclass]
        for item in required_fields
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


    def is_duplicate?()
        resources = DB[:resources]
        auto_cols = [:id, :ah_id, :rdatadateadded, :resource_id]
        cols_to_compare = resources.columns - auto_cols
        h = {}
        for col in cols_to_compare
            h[col] = self.send(col)
        end
        existing = resources.where(Sequel.negate(id: self.id)).where(h)
        if existing.count == 0
            return false
        end
        dep_tables = []
        for table in DB.tables
            dep_tables << table if DB[table].columns.include? :resource_id
        end
        for table in dep_tables
            ds = DB[table]
            cols_to_compare = ds.columns - auto_cols
            rows = self.send table
            for row in rows
                h = {}
                for col in cols_to_compare
                    h[col] = row.send col
                end
                if table == :tags
                    existing = ds.where(h)
                else
                    existing = ds.where(Sequel.negate(id: row.id)).where(h)
                end
                if existing.count == 0
                    return false
                end
            end
        end
        true
    end

    ## Note: this will (re-)set all record_ids.
    def self.set_record_ids()
        resources = DB[:resources]
        h = {}
        count = 1
        Resource.all.each do |resource|
            key = "#{resource.taxonomyid}_#{resource.genome}_#{resource.preparerclass}"
            key += "_#{resource.input_sources.map{|i| i.sourceurl}.join("_")}"
            h[key] = [] unless h.has_key?(key)
            h[key] << resource.id
        end
        h.each_with_index do |(key, value), index|
            for id in value
                r = Resource[id]
                r.record_id = index
                r.save(validate: false)
            end
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
                genome: self.genome, preparerclass: self.preparerclass)
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