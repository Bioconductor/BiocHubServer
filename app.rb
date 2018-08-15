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

def clean_hash(arr)
    arr = arr.map{|i|i.to_hash}
    for item in arr
        item.delete :id
        item.delete :resource_id
    end
    arr
end

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
    h = r.to_hash
    location_prefix = r.location_prefix
    h.delete :location_prefix_id
    h[:location_prefix] = location_prefix[:location_prefix]
    recipe = r.recipe
    h[:recipe] = recipe[:recipe]
    h[:recipe_package] = recipe[:package]
    h.delete :id
    h.delete :ah_id
    h.delete :status_id
    h.delete :recipe_id
    for association in associations
        h[association] = clean_hash(r.send(association.to_s))
    end
    h[:tags] = h[:tags].map{|i|i[:tag]}
    h[:biocversions] = h[:biocversions].map{|i|i[:biocversion]}
    JSON.pretty_generate h
end

get "/newerthan/:date"  do
    # a date in the format 2014-04-01
    pd = params[:date]
    d = DateTime.strptime(pd, "%Y-%m-%d")
    r = Resource.filter{rdatadateadded >  d}.all
    out = []
    for row in r
        v = row.values
        v2 = {}
        v2[:ah_id] = v[:ah_id]
        v2[:title] = v[:title]
        v2[:description] = v[:description].force_encoding("utf-8")
        out.push v2
    end
    out.to_json
end

get "/package/:pkg"  do
    content_type "text/plain"
    r = Resource.filter(:preparerclass => params[:pkg]).all
    out = []
    for row in r
        v = row.values
        v2 = {}
        v2[:id] = v[:id]
        v2[:ah_id] = v[:ah_id]
        v2[:title] = v[:title]
        v2[:description] = v[:description].force_encoding("utf-8")
        out.push v2
    end
    out.to_json
end

get "/title/:ttl"  do
    content_type "text/plain"
    vl = params[:ttl]
    vl.gsub!(" ", "%")
    r = Resource.where(Sequel.ilike(:title, "%#{vl}%")).all
    out = []
    for row in r
        v = row.values
        v2 = {}
        v2[:id] = v[:id]
        v2[:ah_id] = v[:ah_id]
        v2[:title] = v[:title]
        v2[:description] = v[:description].force_encoding("utf-8")
        out.push v2
    end
    out.to_json
end

get "/description/:desc"  do
    content_type "text/plain"
    vl = params[:desc]
    vl.gsub!(" ", "%")
    r = Resource.where(Sequel.ilike(:description, "%#{vl}%")).all
    out = []
    for row in r
        v = row.values
        v2 = {}
        v2[:id] = v[:id]
        v2[:ah_id] = v[:ah_id]
        v2[:title] = v[:title]
        v2[:description] = v[:description].force_encoding("utf-8")
        out.push v2
    end
    out.to_json
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

get '/test' do
    redirect "ftp://ftp.ncbi.nih.gov/snp/organisms/human_9606_b142_GRCh38/VCF/common_all_20150114_papu.vcf.gz.tbi"
end

__END__
