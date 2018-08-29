#!/usr/bin/env ruby

require 'sinatra'
require 'mysql2'
require 'date'
require 'pp'
require 'json'
require 'tmpdir'
require 'socket'
require_relative './db_init'
require_relative './logging_init'

PRODUCTION = !(Socket.gethostname() =~ /^ip-/).nil?

require './models.rb'

basedir = File.dirname(__FILE__)
config = YAML.load_file("#{basedir}/config.yml")
@config = config

sqlite_filename = "#{config['dbname']}.sqlite3"

helpers do
    def protected!
        # ignore auth unless we are on production
        return unless PRODUCTION
        return if authorized?
        headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
        halt 401, "Not authorized\n"
    end

    def authorized?
      basedir = File.dirname(__FILE__)
      config = YAML.load_file("#{basedir}/config.yml")
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? and @auth.basic? and @auth.credentials and
        @auth.credentials == ['admin', config['admin_password']]
    end

    def log_request(request, url, rdatapath_id, resource_id)
        # FIXME only do this if we are on production!
        begin # don't let logging interfere with redirection
            # do we need a transaction for one statement?
            LOGGING_DB[:log_entries].insert(
                :timestamp => DateTime.now,
                :remote_ip => request.ip,
                :url => url,
                :resource_fetched => resource_id,
                :id_fetched => rdatapath_id,
                :is_s3 => false,
                :referrer => request.referrer,
                :user_agent => request.user_agent
            )
        rescue Exception => ex# handle specific exceptions?
            puts "exception: #{ex.message}"
        end
    end

end




##############################################
#
# More helper functions
#
##############################################

def clean_hash(arr)
    arr = arr.map{|i|i.to_hash}
    for item in arr
        item.delete :id
        item.delete :resource_id
    end
    arr
end

def formatId(r, associations)
    h = r.to_hash
    location_prefix = r.location_prefix
    h.delete :location_prefix_id
    h[:location_prefix] = location_prefix[:location_prefix]
    recipe = r.recipe
    h[:recipe] = recipe[:recipe]
    h[:recipe_package] = recipe[:package]
    h.delete :record_id
    h.delete :status_id
    h.delete :recipe_id
    for association in associations
        h[association] = clean_hash(r.send(association.to_s))
    end
    h[:tags] = h[:tags].map{|i|i[:tag]}
    h[:biocversions] = h[:biocversions].map{|i|i[:biocversion]}
    h
end

def formatOutput(r)
    out = []
    for row in r
        v = row.values
        v2 = {}
        v2[:ah_id] = v[:ah_id]
        v2[:title] = v[:title]
        v2[:description] = v[:description].force_encoding("utf-8")
        rp = Rdatapath.find(:resource_id=> v[:id])
        path = rp.rdatapath
        resource = rp.resource
        prefix = resource.location_prefix.location_prefix
        url = prefix + path
        v2[:download] = url
        out.push v2
    end
    out
end

def getcols()
    #cols = Resource.columns + Rdatapath.columns + InputSource.columns
    cols = ["title", "dataprovider", "species", "taxonomyid", "genome",
            "description", "newerthan", "rdataclass", "sourceurl",
            "sourceversion", "sourcetype"]
    cols
end

def whichtable(vl)
    h = {}
    h[:title] = "Resource"
    h[:dataprovider] = "Resource"
    h[:species] = "Resource"
    h[:taxonomyid] = "Resource"
    h[:genome] = "Resource"
    h[:description] = "Resource"
    h[:newerthan] = "Resource"
    h[:rdataclass] = "Rdatapath"
    h[:sourceurl ] = "InputSource"
    h[:sourceversion] = "InputSource"
    h[:sourcetype] = "InputSource"
    h[:"#{vl}"]
end

def matchResource(column, vl)
     vls = vl.split(",").collect{|v| v.strip || v}
     out = []
     e1 = vls.shift
     if column == "newerthan"
         d = DateTime.strptime(e1, "%Y-%m-%d")
         r = Resource.filter{rdatadateadded >  d}.all
         for row in r
              v = row.values
              out.push v[:id]
         end
     else
         r = Resource.where(Sequel.ilike(:"#{column}", ("%" + e1 + "%"))).all
         for row in r
             v = row.values
             out.push v[:id]
         end
         if vls.length > 0
             vls.each do |s|
                 r = Resource.where(Sequel.ilike(:"#{column}", ("%" + s + "%"))).all
                 find = []
                 for row in r
                     v = row.values
                     find.push v[:id]
                 end
                 out = out & find
             end
         end
     end
     out
end

def matchInput(column, vl)
     vls = vl.split(",").collect{|v| v.strip || v}
     out = []
     e1 = vls.shift
     r = InputSource.where(Sequel.ilike(:"#{column}", ("%" + e1 + "%"))).all
     for row in r
         v = row.values
         out.push v[:id]
     end
     if vls.length > 0
         vls.each do |s|
             r = InputSource.where(Sequel.ilike(:"#{column}", ("%" + s + "%"))).all
             find = []
             for row in r
                 v = row.values
                 find.push v[:id]
             end
             out = out & find
         end
     end
     out
 end

def matchRdatapath(column, vl)
     vls = vl.split(",").collect{|v| v.strip || v}
     out = []
     e1 = vls.shift
     r = Rdatapath.where(Sequel.ilike(:"#{column}", ("%" + e1 + "%"))).all
     for row in r
         v = row.values
         out.push v[:id]
     end
     if vls.length > 0
         vls.each do |s|
             r = Rdatapath.where(Sequel.ilike(:"#{column}", ("%" + s + "%"))).all
             find = []
             for row in r
                 v = row.values
                 find.push v[:id]
             end
             out = out & find
         end
     end
     out
end


def getIds(vl, column)
    vls = vl.split(" ")
    out = []
    e1 = vls.shift
    r = Resource.where(Sequel.ilike(:"#{column}", ("%" + e1 + "%"))).all
    for row in r
        v = row.values
        out.push v[:id]
    end

    if vls.length > 0
        vls.each do |s|
            r = Resource.where(Sequel.ilike(:"#{column}", ("%" + s + "%"))).all
            find = []
            for row in r
                v = row.values
                find.push v[:id]
            end
            out = out & find
        end
    end
    out
end


##############################################
#
# API functions
#
##############################################

get "/" do
    erb :index, :locals => {:dbname => "#{sqlite_filename}"}
end

get "/metadata/#{sqlite_filename}" do
    if config['dbtype'] == "sqlite"
        send_file "#{basedir}/#{sqlite_filename}",
            :filename => "#{sqlite_filename}"
    else
        send_file "#{basedir}/#{sqlite_filename}"
    end
end

get "/metadata/schema_version" do
    if DB.table_exists? :schema_info
        DB[:schema_info].first[:version].to_s
    else
        "0"
    end
end

get '/metadata/database_timestamp' do
    content_type "text/plain"
    DB[:timestamp].first[:timestamp].to_s
end

get '/metadata/highest_id' do
    content_type "text/plain"
    DB[:resources].max(:id).to_s
end

get "/id/:id" do
    content_type "text/plain"
    associations = [:rdatapaths, :input_sources, :tags, :biocversions]
    r = Resource.filter(:id => params[:id]).eager(associations).all.first
    h = formatId(r, associations)
    JSON.pretty_generate h
end

get "/ahid/:id" do
    content_type "text/plain"
    associations = [:rdatapaths, :input_sources, :tags, :biocversions]
    id = params[:id]
    if (id[0..1].upcase.start_with?("AH"))
        id = id.sub(/^../, "AH")
    elsif
        id = "AH" + id
    end
    r = Resource.filter(:ah_id => "#{id}").eager(associations).all.first
    h = formatId(r, associations)
    JSON.pretty_generate h
end

get "/newerthan/:date"  do
    # a date in the format 2014-04-01
    pd = params[:date]
    d = DateTime.strptime(pd, "%Y-%m-%d")
    r = Resource.filter(:status_id => '2').filter{rdatadateadded >  d}.all
    out = formatOutput(r)
    erb :resultsPage , :locals => {:result => out}
end

# accurate for ExperimentHub but not AnnotationHub
# next version should have this as separate database field
get "/package2/:pkg"  do
    r = Resource.filter(:preparerclass => params[:pkg]).filter(:status_id => '2').all
    out = formatOutput(r)
    erb :resultsPage , :locals => {:result => out}
end

get "/package/:pkg" do
    vl = params[:pkg]
    r = Rdatapath.where(Sequel.ilike(:rdatapath, "%#{vl}%")).all
    out = []
    for row in r
        v = row.values
        out.push v[:resource_id]
    end
    r = Resource.where(id: out).filter(:status_id => '2').all
    out = formatOutput(r)
    erb :resultsPage , :locals => {:result => out}
end

get "/title/:ttl"  do
    vl = params[:ttl]
    out = getIds(vl, "title")
    r = Resource.where(id: out).filter(:status_id => '2').all
    out = formatOutput(r)
    erb :resultsPage , :locals => {:result => out}
end


get "/description/:desc"  do
    vl = params[:desc]
    out = getIds(vl, "description")
    r = Resource.where(id: out).filter(:status_id => '2').all
    out = formatOutput(r)
    erb :resultsPage , :locals => {:result => out}
end

get "/dataprovider"  do
    r = Resource.select(:dataprovider).all
    out = []
    for row in r
        v = row.values
        out.push v[:dataprovider]
    end
    erb :listing , :locals => {:message => "Available Data Providers:",
                               :link => "dataprovider",
                               :values => out.uniq}
end

get "/dataprovider/:dp"  do
    vl = params[:dp]
    vl = vl.gsub("%20", " ")
    r = Resource.where(Sequel.ilike(:dataprovider, "%#{vl}%")).filter(:status_id => '2').all
    out = formatOutput(r)
    erb :resultsPage , :locals => {:result => out}
end

get "/species"  do
    r = Resource.select(:species).all
    out = []
    for row in r
        v = row.values
        out.push v[:species]
    end
    erb :listing , :locals => {:message => "Available Species:",
                               :link => "species",
                               :values => out.uniq}
end

get "/species/:spc"  do
    vl = params[:spc]
    vl = vl.gsub("%20", " ")
    r = Resource.where(Sequel.ilike(:species, "%#{vl}%")).filter(:status_id => '2').all
    out = formatOutput(r)
    erb :resultsPage , :locals => {:result => out}
end

get "/taxonomyid"  do
    r = Resource.select(:taxonomyid).all
    out = []
    for row in r
        v = row.values
        out.push v[:taxonomyid]
    end
    erb :listing , :locals => {:message => "Available TaxonomyId:",
                               :link => "taxonomyid",
                               :values => out.uniq}
end

get "/taxonomyid/:tax"  do
    r = Resource.filter(:taxonomyid => params[:tax]).filter(:status_id => '2').all
    out = formatOutput(r)
    erb :resultsPage , :locals => {:result => out}
end

get "/genome"  do
    r = Resource.select(:genome).all
    out = []
    for row in r
        v = row.values
        out.push v[:genome]
    end
    erb :listing , :locals => {:message => "Available Genome:",
                               :link => "genome",
                               :values => out.uniq}
end

get "/genome/:gn"  do
    r = Resource.filter(:genome => params[:gn]).filter(:status_id => '2').all
    out = formatOutput(r)
    erb :resultsPage , :locals => {:result => out}
end

get "/rdataclass"  do
    r = Rdatapath.select(:rdataclass).all
    out = []
    for row in r
        v = row.values
        out.push v[:rdataclass]
    end
    erb :listing , :locals => {:message => "Available rdataclass:",
                               :link => "rdataclass",
                               :values => out.uniq}
end

get "/rdataclass/:rdc" do
    r = Rdatapath.filter(:rdataclass => params[:rdc]).all
    out = []
    for row in r
        v = row.values
        out.push v[:resource_id]
    end
    r = Resource.where(id: out).filter(:status_id => '2').all
    out = formatOutput(r)
    erb :resultsPage , :locals => {:result => out}
end

get "/rdatapath/:rdp" do
    vl = params[:rdp]
    vls = vl.split(" ")
    out = []
    e1 = vls.shift
    r = Rdatapath.where(Sequel.ilike(:rdatapath, ("%" + e1 + "%"))).all
    for row in r
        v = row.values
        out.push v[:resource_id]
    end
    if vls.length > 0
        vls.each do |s|
            r = Rdatapath.where(Sequel.ilike(:rdatapath, ("%" + s + "%"))).all
            find = []
            for row in r
                v = row.values
                find.push v[:resource_id]
            end
            out = out & find
        end
    end
    r = Resource.where(id: out).filter(:status_id => '2').all
    out = formatOutput(r)
    erb :resultsPage , :locals => {:result => out}
end

get "/sourcetype"  do
    r = InputSource.select(:sourcetype).all
    out = []
    for row in r
        v = row.values
        out.push v[:sourcetype]
    end
    erb :listing , :locals => {:message => "Available Source Types:",
                               :link => "sourcetype",
                               :values => out.uniq}
end

get "/sourcetype/:srct" do
    r = InputSource.filter(:sourcetype => params[:srct]).all
    out = []
    for row in r
        v = row.values
        out.push v[:resource_id]
    end
    r = Resource.where(id: out).filter(:status_id => '2').all
    out = formatOutput(r)
    erb :resultsPage , :locals => {:result => out}
end

get "/sourceversion"  do
    r = InputSource.select(:sourceversion).all
    out = []
    for row in r
        v = row.values
        out.push v[:sourceversion]
    end
    erb :listing , :locals => {:message => "Available Source Versions:",
                               :link => "sourceversion",
                               :values => out.uniq}
end

get "/sourceversion/:srcv" do
    r = InputSource.filter(:sourceversion => params[:srcv]).all
    out = []
    for row in r
        v = row.values
        out.push v[:resource_id]
    end
    r = Resource.where(id: out).filter(:status_id => '2').all
    out = formatOutput(r)
    erb :resultsPage , :locals => {:result => out}
end

get "/sourceurl/:srcurl" do
    vl = params[:srcurl]
    vls = vl.split(" ")
    out = []
    e1 = vls.shift
    r = InputSource.where(Sequel.ilike(:sourceurl, ("%" + e1 + "%"))).all
    for row in r
        v = row.values
        out.push v[:resource_id]
    end
    if vls.length > 0
        vls.each do |s|
            r = InputSource.where(Sequel.ilike(:sourceurl, ("%" + s + "%"))).all
            find = []
            for row in r
                v = row.values
                find.push v[:resource_id]
            end
            out = out & find
        end
    end
    r = Resource.where(id: out).filter(:status_id => '2').all
    out = formatOutput(r)
    erb :resultsPage , :locals => {:result => out}
end

get '/recordstatus/:id' do
    content_type "text/plain"
    id = params[:id]
    if (id[0..1].upcase.start_with?("AH"))
        id = id.sub(/^../, "AH")
    elsif
        id = "AH" + id
    end
    r = Resource.filter(:ah_id => id).all.first[:status_id]
    DB[:statuses].filter(:id => r).all.first[:status]
end

get '/query/:qry' do
    qry = params[:qry]
    out = []
    qry.split(/[()]+/).each do |v|
        out.push v.strip
    end
    vls = out.select.with_index { |_, i| i.odd? }
    keys = out.select.with_index { |_, i| i.even? }
    invalid = keys - getcols()
    allidx = []
    if invalid.length > 0
        erb :error , :locals => {:message => "Invalid query term:",
                                 :offenders => invalid.join("<br/>"),
                                 :helper => "Available query terms:<br/>",
                                 :helper2 => getcols().join("<br/>")}
    else
         method = whichtable(keys[0])
         case method
         when "Resource"
             idx = matchResource(keys[0], vls[0])
         when "InputSource"
             idx = matchInput(keys[0], vls[0])
         when "Rdatapath"
             idx = matchRdatapath(keys[0], vls[0])
         else
         end
         allidx = idx

         dx = 1
         while dx < keys.length
             method = whichtable(keys[dx])
             case method
             when "Resource"
                 idx = matchResource(keys[dx], vls[dx])
             when "InputSource"
                 idx = matchInput(keys[dx], vls[dx])
             when "Rdatapath"
                 idx = matchRdatapath(keys[dx], vls[dx])
             else
             end
             allidx = allidx & idx
             dx  = dx + 1
         end
         r = Resource.where(id: allidx).filter(:status_id => '2').all
         out = formatOutput(r)
         erb :resultsPage , :locals => {:result => out}
    end
end

get '/fetch/:id' do
    rp = Rdatapath.find(:id=>params[:id])
    path = rp.rdatapath
    resource = rp.resource
    prefix = resource.location_prefix.location_prefix
    url = prefix + path
    unless prefix == "http://s3.amazonaws.com/annotationhub/"
        # FIXME only do this if we are on production...
        log_request(request, url, rp.id, resource.id)
    end
    redirect url
end

get '/log_fetch' do
    rp = Rdatapath.find(:id=>params[:id])
    path = rp.rdatapath
    resource = rp.resource
    prefix = resource.location_prefix.location_prefix
    url = prefix + path
    unless prefix == "http://s3.amazonaws.com/annotationhub/"
        # FIXME only do this if we are on production...
        log_request(request, url, rp.id, resource.id)
    end
    url
end




##############################################
#
# Protected actions
#
##############################################




post '/resource' do
    protected!
    unless params.has_key? "payload"
        status 500
        return "no 'payload' parameter!"
    end
    obj = nil
    begin
        obj = JSON.parse(params[:payload])
    rescue
        status 500
        return "could not parse payload"
    end

    if obj.has_key? "biocversions" and obj["biocversions"].is_a? String
        obj["biocversions"] = [obj["biocversions"]]
    end

    rsrc = {}
    obj.each_pair do |key, value|
        if key == "recipe_package" and value.is_a? Array and value.uniq.length == 1
            value = value.first
        end
        rsrc[key] = value unless value.is_a? Array or value.is_a? Hash
    end

    unless rsrc.has_key? "location_prefix"
        status 500
        return "no location_prefix"
    end

    # fixme - check for duplicates, either here or in valid?()

    # start transaction here
    resource = nil
    begin
        DB.transaction(:rollback => :reraise) do
            lp = LocationPrefix.find_or_create(:location_prefix =>
                rsrc["location_prefix"])
            rsrc.delete "location_prefix"
            rsrc["location_prefix_id"] = lp.id

            if rsrc.has_key? "recipe" and rsrc.has_key? "recipe_package"
                recipe = Recipe.find_or_create(:recipe => rsrc["recipe"],
                    :package=>rsrc["recipe_package"])
                rsrc.delete "recipe"
                rsrc.delete "recipe_package"
                rsrc["recipe_id"] = recipe.id
            end

            resource = Resource.new rsrc
            unless resource.valid?
                status 500
                return "invalid resource: #{resource.errors}"
            end

            # fixme - make sure rdatapaths exist and are valid
            resource.status_id = Status.find(:status => "Public").id

            begin
                resource.save
            rescue Exception => ex
                if ex.message == "the before_create hook failed"
                    status "500"
                    return "attempt to insert duplicate record"
                else
                    status "500"
                    return "exception: #{ex.message}"
                end
            end

            if obj.has_key? "rdatapaths"
                for rdatapath in obj["rdatapaths"]
                    rdatapath["resource_id"] = resource.id
                    # fixme - shouldn't need this after a while
                    # if rdatapath.has_key? "derivedmd5"
                    #     rdatapath["rdatamd5"] = rdatapath.delete("derivedmd5")
                    # end
                    Rdatapath.create(rdatapath)
                end
            end


            for input_source in obj["input_sources"]
                input_source["resource_id"] = resource.id
                InputSource.create(input_source)
            end

            for tag in obj["tags"]
                Tag.create(:resource_id => resource.id, :tag => tag)
            end

            for biocversion in obj["biocversions"]
                Biocversion.create(:resource_id => resource.id,
                    :biocversion => biocversion)
            end
        end

        if resource.is_duplicate?
            raise Sequel::Rollback, "This is a duplicate record!"
        end

        resource.record_id = resource.get_record_id()
        if resource.record_id.nil?
            raise Sequel::Rollback "record_id should not be nil!"
        end
        resource.save()

    rescue Exception => ex
        status 500
        return ex.message
    end
    "ok, resource id is #{resource.id}"
end

delete "/resource/:id" do
    protected!
    r = Resource.find(:id=>params[:id])
    associations = [:rdatapaths, :input_sources, :tags, :biocversions]
    for assoc in associations
        a = r.send assoc
        a.each{|i| i.destroy}
    end
    r.destroy
    status 200
    "OK"
end






##############################################
#
# Tests
#
##############################################

#get '/test' do
#    redirect "ftp://ftp.ncbi.nih.gov/snp/organisms/human_9606_b142_GRCh38/VCF/common_all_20150114_papu.vcf.gz.tbi"
#end

get '/test4' do
    redirect "/"
end


__END__
