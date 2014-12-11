#!/usr/bin/env ruby

require 'aws'
require 'yaml'
require 'sequel'

require_relative './logging_init'

@rgo = Regexp.new('REST\.GET\.OBJECT')

def parse(line, file)
    return nil unless line.match(@rgo)
    unless instance_variable_defined?(:@regex)
        #13784cc045aa79ecb3e164200025c7fc9205241e61ba76f40d486de657f5df52 annotationhub [19/Nov/2013:23:34:51 +0000] 140.107.151.128 - 8151DFA13868F466 REST.GET.OBJECT release-69/fasta/callithrix_jacchus/ncrna/Callithrix_jacchus.C_jacchus3.2.1.69.ncrna.fa_0.0.1.json "GET /release-69/fasta/callithrix_jacchus/ncrna/Callithrix_jacchus.C_jacchus3.2.1.69.ncrna.fa_0.0.1.json HTTP/1.1" 403 AccessDenied 231 - 7 - "-" "curl/7.30.0" -
        #@regex = Regexp.new('(?<owner>\S+) (?<bucket>\S+) (?<time>\[[^\]]*\]) (?<remote_ip>\S+) (?<requester>\S+) (?<reqid>\S+) (?<operation>\S+) (?<raw_url>\S+) "?(?<request>[^" ]*)"? (?<http_status>\S+) (?<s3_error_code>\S+) (?<bytes_sent>\S+) (?<object_size>\S+) (?<total_time>\S+) (?<turn_around_time>\S+) (?<referrer>"[^"]*") (?<user_agent>"[^"]*") (?<s3_version_id>\S)')
        @regex = Regexp.new '(?<owner>\S+) (?<bucket>\S+) (?<time>\[[^\]]*\]) (?<remote_ip>\S+) (?<requester>\S+) (?<reqid>\S+) (?<operation>\S+) (?<raw_url>\S+) "?(?<request>[^"]*)"? (?<http_status>\S+) (?<s3_error_code>\S+) (?<bytes_sent>\S+) (?<object_size>\S+) (?<total_time>\S+) (?<turn_around_time>\S+) (?<referrer>"[^"]*") (?<user_agent>"[^"]*") (?<s3_version_id>\S)'
    end
    md = @regex.match line
    if md.nil?
        puts "in file #{file}:"
        puts "regex did not match line!"
        puts line
        return nil
    end
    #return nil unless md[:operation] == "REST.GET.OBJECT"
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
            hsh[:url] = 'http://s3.amazonaws.com/annotationhub/' + md[name]
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

