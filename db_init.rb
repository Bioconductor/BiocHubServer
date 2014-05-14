require 'sequel'

unless defined? DB
    mode = nil
    if ENV['AHS_DATABASE_TYPE'].nil? or 
      !(["mysql", "sqlite"].include? ENV['AHS_DATABASE_TYPE'])
        puts "environment variable AHS_DATABASE_TYPE must be set to"
        puts "mysql or sqlite."
        exit
    else
        mode = ENV['AHS_DATABASE_TYPE'].to_sym
    end

    url = nil
    if mode == :mysql
        url = "mysql://ahuser:password@localhost/ahtest"
    else
        url = "sqlite://#{File.dirname(__FILE__)}/ahtest.sqlite3"
    end

    DB = Sequel.connect(url)
end

