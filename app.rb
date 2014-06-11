#!/usr/bin/env ruby

require 'sinatra'
require 'mysql'
require 'date'
require 'pp'
require 'json'
require_relative './db_init' 


require './models.rb'


def get_value(thing)
    return thing if thing.empty?
    thing.map{|i| i.values}
end

get "/" do 
    "try appending /newerthan/2014-04-01 or /schema_info to the current url."
end

get "/newerthan/:date"  do
    # a date in the format 2014-04-01
    pd = params[:date]
    d = DateTime.strptime(pd, "%Y-%m-%d")
    x = Version.filter{rdatadateadded >  d}.select(:resource_id).all
    ids = x.map{|i| i.resource_id }
    r = Resource.filter(:id => ids).eager(:rdatapaths,
        :input_sources, :tags, :biocversions, :recipes).all
    out = []
    for row in r
        v = row.values
        v[:description] = v[:description].force_encoding("utf-8")
        v[:rdatapaths] = get_value row.rdatapaths
        v[:input_sources] = get_value row.input_sources
        v[:tags] = get_value row.tags
        v[:biocversions] = get_value row.biocversions
        #FIXME v[:recipes] = get_value row.recipes
        out.push v
        v.to_json
    end
    out.to_json
end

def clean_hash(arr)
    arr = arr.map{|i|i.to_hash}
    for item in arr
        item.delete :id
        item.delete :resource_id
    end
    arr
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

post '/new_resource' do
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
    # #...
    rsrc = {}
    obj.each_pair do |key, value|
        rsrc[key] = value unless value.is_a? Array or value.is_a? Hash
    end

    unless rsrc.has_key? "location_prefix"
        status 500
        return "no location_prefix"
    end

    # start transaction here
    DB.transaction do


        lp = LocationPrefix.find_or_create(:location_prefix => rsrc["location_prefix"])
        rsrc.delete "location_prefix"
        rsrc["location_prefix_id"] = lp.id

        recipe = Recipe.find_or_create(:recipe => rsrc["recipe"],
            :package=>rsrc["recipe_package"])
        rsrc.delete "recipe"
        rsrc.delete "recipe_package"
        rsrc["recipe_id"] = recipe.id

        resource = Resource.new rsrc
        unless resource.valid?
            status 500
            return "invalid resource: #{resource.errors}"
        end

        # fixme - make sure rdatapaths exist and are valid
        resource.save 
        require 'pry'; binding.pry
        # rdatapath.save
        # ...


    end

    "ok"
end

get '/test' do
    "sorry\n"
end

get "/schema_version" do
    if DB.table_exists? :schema_info
        DB[:schema_info].first[:version].to_s
    else
        "0"
    end
end

__END__

get "/dump_schema" do 
end

post "/new_resource" do 
    # is it a valid object? 
        # add it to database
    # else
        # error
end