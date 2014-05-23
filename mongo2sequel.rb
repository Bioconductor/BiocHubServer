#!/usr/bin/env ruby 

# FIXME - make sure refnet records are included!
# "RDataPath"=>"refnet/hypoxiaSignaling-2006.tsv_0.0.1.RData"} is not....

require 'fileutils'
require 'mongo'
require_relative './db_init'
require 'pp'
require 'json'
require 'pry'

# encodefiles = ["wgEncodeCshlLongRnaSeq", "wgEncodeCshlShortRnaSeq",
#     "wgEncodeRikenCage"]

# for file in encodefiles
#     unless File.exists? file
#         `curl http://hgdownload.cse.ucsc.edu/goldenpath/hg19/encodeDCC/#{file}/files.txt > #{file}`
#     end
# end


include Mongo

client = MongoClient.new
db = client.db("AnnotationHub")
coll=db['metadata']

# for now, just find one document instead of looping through all of them:


require './models.rb'

lp = LocationPrefix.create(:location_prefix => "http://s3.amazonaws.com/annotationhub/")
st = Status.create(:status=>"public")
#doc = coll.find_one

# the supposedly good way to do this is to use a cursor:
#coll.find.each do |doc|

# but it seems to crash, so let's read it all into memory:

alldocs = coll.find.to_a


# some (but not all? refnet records have no BiocVersion. FIXME make sure the good ones get in.)
baddocs = alldocs.find_all{|i| not i.has_key? "BiocVersion"}
baddocs += alldocs.find_all{|i| i["Description"].nil?}

docs = alldocs - baddocs

#hmmdocs = alldocs.find_all{|i| i["BiocVersion"].class.to_s == "String"}

#docs = hmmdocs # remove this!

# puts hmmdocs.length

# pp hmmdocs.first



# to get all recipe names:
rnames = {}
docs.each do |i|
  rnames[i["Recipe"]] = 1 if i["Recipe"].is_a? String
  rnames[i["Recipe"][""]] = 1 if i["Recipe"].is_a? Hash
end


# get the ones that are strings, not hashes:
docs.each{|i|rnames[i["Recipe"]] = 1 if i.has_key? "Recipe" and i["Recipe"].is_a? String}

# names are in rnames.keys

# to get all recipe args
@argnames = {}
docs.each{|i|@argnames[i["RecipeArgs"]] = 1 if i.has_key? "RecipeArgs"};
# args are in argnames.keys

# NOTE: hardcoding all recipe packages to AnnotationHubData


@argnames.keys.each_with_index do |key, i|
    names = ["broadpeakBedToGRanges", "narrowpeakBedToGRanges",
        "bedrnaelementsToGRanges"]
    Recipe.create(:recipe => names[i], :package=> "AnnotationHubData")
end


for recipe in rnames.keys
    rcp = Recipe.create(:recipe => recipe, :package => "AnnotationHubData")
end


recipes0 = Recipe.find_all
@recipes = recipes0.each {|i| i.to_hash}




def get_matching_recipe_id(doc)

    if doc.has_key? "RecipeArgs"
        if doc["RecipeArgs"].respond_to? :keys
            colClasses = doc["RecipeArgs"].to_hash["colClasses"]
            if  colClasses.has_key? "signif"
                return @recipes.find {|i|i[:recipe] == "bedrnaelementsToGRanges"}.id
            elsif colClasses.has_key? "peak"
                return @recipes.find {|i|i[:recipe] == "narrowpeakBedToGRanges"}.id
            else
                return @recipes.find {|i|i[:recipe] == "broadpeakBedToGRanges"}.id
            end
                
        end
    end
    if doc.has_key? "Recipe"
        if doc["Recipe"].is_a? String
            return @recipes.find{|i| i.recipe == doc["Recipe"]}[:id]
        else
            return @recipes.find{|i| i.recipe == doc["Recipe"][""]}[:id]
        end
    end
    return nil
end

#docs = docs.find_all{|i| i["Recipe"].empty?} # remove this!!!!!!

### REMOVE THIS:
#docs = docs.find_all{|i| i["SourceUrl"] =~ /wgEncodeCshlLongRnaSeq|wgEncodeCshlShortRnaSeq|wgEncodeRikenCage/}
#binding.pry

### END REMOVE


# and then loop through it
docs.each_with_index do |doc, i|
    # puts i if i > 6835
    # pp doc if i > 6835

    #puts i if i % 100 == 0
    r = Resource.create(
        :title => doc["Title"],
        :coordinate_1_based => doc["Coordinate_1_based"],
        :dataprovider => doc["DataProvider"],
        :species => doc["Species"],
        :taxonomyid => doc["TaxonomyId"].to_i, # should this really be an integer?
        :description => doc["Description"].force_encoding("ASCII-8BIT").encode('UTF-8', undef: :replace, replace: ''),
        :genome => doc["Genome"],
        :maintainer => doc["Maintainer"],
        :rdataversion => doc["RDataVersion"],
        :rdatadateadded => doc["RDataDateAdded"]

    )

    r.recipe_id = get_matching_recipe_id(doc)

    r.location_prefix= lp
    r.status= st

    r.save

    # what if there is more than one (of any of these)?
    rdatalastmodifieddate = doc.has_key?("RDataLastModifiedDate") \
        ? doc["RDataLastModifiedDate"] : nil
    r.add_rdatapath Rdatapath.new(
        :rdatapath => doc["RDataPath"],
        :rdataclass => doc["RDataClass"],
        :rdatasize => doc["RDataSize"],
        # no mongo docs have derivedmd5
        :rdatalastmodifieddate => rdatalastmodifieddate
    )


#    if doc["BiocVersion"].class.to_s == "String"
        # FIXME - make this more future(and past)-proof
        doc["BiocVersion"] = ["2.12", "2.13", "2.14", "3.0"]
#    end


    for biocversion in doc["BiocVersion"]
        bv = Biocversion.create(:biocversion => biocversion)
        r.add_biocversion bv
    end



    tags = doc["Tags"]
    if doc["Tags"].is_a? Hash 
        tags = []
        doc["Tags"].each_pair do |k,v|
            if k.empty?
                tags << v
            else
                tags << "#{k}=#{v}"
            end
        end
    end

    for tag in tags
        t = Tag.create(:tag => tag)
        r.add_tag t
    end



    inputsource = {}
    inputsource[:sourcefile] = doc["SourceFile"]
    inputsource[:sourcesize] = doc["SourceSize"] if doc.has_key? "SourceSize"
    inputsource[:sourceurl] = doc["SourceUrl"]
    inputsource[:sourceversion] = doc["SourceVersion"]
    # no mongo docs have sourcemd5 or sourcelastmodifieddate
    r.add_input_source InputSource.new (inputsource)

end

