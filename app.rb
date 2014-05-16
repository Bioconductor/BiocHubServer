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
    # fixme recipes
    h.delete :id
    h.delete :ah_id
    h.delete :status_id
    for association in associations
        h[association] = clean_hash(r.send(association.to_s))
    end
    JSON.pretty_generate h
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