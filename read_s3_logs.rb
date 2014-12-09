#!/usr/bin/env ruby

require 'aws'
require 'yaml'
require 'sequel'

require_relative './logging_init'


def parse(line, file)
    unless instance_variable_defined?(:@regex)
        @regex = Regexp.new('^(?<owner>\S+) (?<bucket>\S+) (?<time>\[[^\]]*\]) (?<remote_ip>\S+) (?<requester>\S+) (?<reqid>\S+) (?<operation>\S+) (?<raw_url>\S+) (?<request>"[^"]*") (?<http_status>\S+) (?<s3_error_code>\S+) (?<bytes_sent>\S+) (?<object_size>\S+) (?<total_time>\S+) (?<turn_around_time>\S+) (?<referrer>"[^"]*") (?<user_agent>"[^"]*") (?<s3_version_id>\S)$')
    end
    md = @regex.match line
    if md.nil?
        puts "in file #{file}:"
        puts "regex did not match line!"
        puts line
        return nil
    end
    return nil unless md[:operation] == "REST.GET.OBJECT"
    hsh = {}
    hsh[:is_s3] = true
    md.names.each do |name|
        sym = name.to_sym
        if @logfiles_columns.include? sym
            hsh[name.to_sym] = md[name]
        elsif name == 'time'
            hsh[:timestamp] = DateTime.strptime(md[name],
                "[%d/%b/%Y:%H:%M:%S %z]")
        elsif name == 'raw_url'
            hsh[:url] = 'http://s3.amazonaws.com/annotationhub/' + url
        end
    end
    hsh
end

basedir = File.dirname(__FILE__)
config = YAML.load_file("#{basedir}/config.yml")

AWS.config(:access_key_id => config["access_key_id"],
    :secret_access_key => config["secret_access_key"])
s3 = AWS::S3.new
bucket = s3.buckets["annotationhub-logging"] 
keys = []
logfiles = LOGGING_DB[:s3_log_files]
log_entries = LOGGING_DB[:log_entries]
@logfiles_columns = log_entries.columns
logfilenames = {}
logfiles.all {|i| logfilenames[i[:filename]] = 1}
bucket.objects.each {|i| keys << i}
keys.each_with_index do |key, idx|
    puts idx if idx % 100 == 0
    next if logfilenames.has_key? key
    f = StringIO.new
    key.read do |chunk|
        f.write chunk
    end
    lines = f.string.split "\n"
    lines.each do |line|
        hsh = parse(line, key.key)
        next if hsh.nil?

        begin
            LOGGING_DB.transaction(:rollback => :reraise) do 
                log_entries.insert(hsh)
                unless logfilenames.has_key? key.key
                    logfiles.insert(:filename => key.key)
                    logfilenames[key.key] = 1
                end
            end
        rescue Sequel::Rollback => ex
            logfilenames.delete key.key
            puts "in rescue"
        end
    end
end

