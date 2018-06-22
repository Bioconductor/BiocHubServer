require 'sequel'
require 'yaml'
require 'logger'

unless defined? DB
    basedir = File.dirname(__FILE__)
    config = YAML.load_file("#{basedir}/config.yml")

    if `hostname` =~ /^ip-/ and config['dbtype'].nil?
        config['dbtype']='mysql'
    end

    mode = nil
    if config['dbtype'].nil? or
      !(["mysql", "sqlite"].include? config['dbtype'])
        puts "dbtype must be set to mysql or sqlite in config.yml."
        exit
    else
        mode = config['dbtype'].to_sym
    end

    url = nil
    if mode == :mysql
        url = config['mysql_url']
    else
        url = "sqlite://#{basedir}/#{config['dbname']}.sqlite3"
    end

    DB = Sequel.connect(url)
end

DB.loggers << Logger.new($stdout)
