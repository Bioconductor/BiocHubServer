
# Run me via cron.


ENV['AHS_DATABASE_TYPE'] = 'mysql'

require './db_init.rb'
require 'fileutils'
require 'sequel'

@basedir = File.dirname(__FILE__)


timestamp =  DB[:timestamp].first[:timestamp]

cachefile = "#{@basedir}/dbtimestamp.cache"

@config = YAML.load_file("#{@basedir}/config.yml")



def convert_db()
    outfile = "#{@basedir}/#{@config['sqlite_filename']}"
    outfile_tmp = outfile + "_tmp"
    FileUtils.rm_rf outfile_tmp
    res = `sequel #{@config['mysql_url']} -C sqlite://#{outfile_tmp}`
    FileUtils.rm_rf outfile
    FileUtils.mv outfile_tmp, outfile
    #puts "does it exist? #{File.exists? outfile}"
end


if (File.exists?(cachefile))
    cached_time = Time.parse(File.readlines(cachefile).first)
    if (timestamp > cached_time)
        convert_db()
    end
else
    convert_db()
end

f = File.open(cachefile, "w")
f.write(timestamp.to_s)
f.close


