basedir = File.dirname(__FILE__)

require_relative "../models.rb"

Sequel.migration do
  up do
    lp = LocationPrefix.create(location_prefix: "http://www.pazar.info/")
  end

  down do
    DB[:location_prefixes].where(location_prefix: "http://www.pazar.info/").delete
  end
end