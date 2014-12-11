#!/usr/bin/env ruby

line = '79a59df900b949e55d96a1e698fbacedfd6e09d98eacf8f8d5218e7cd47ef2be mybucket [06/Feb/2014:00:00:38 +0000] 192.0.2.3 79a59df900b949e55d96a1e698fbacedfd6e09d98eacf8f8d5218e7cd47ef2be 3E57427F3EXAMPLE REST.GET.VERSIONING - "GET /mybucket?versioning HTTP/1.1" 200 - 113 - 7 - "-" "S3Console/0.4" -'

ss = line.split " "

out = []

in_delimited = false

count = 0
loop do
    seg = ss[count]
    if seg.start_with? "[" or seg.start_with? '"'
        delim = seg.split("")[0]
        if delim == '['
            end_delim = ']'
        else 
            end_delim = '"'
        end
        tmp = ""
        loop do
            tmp = tmp + seg
            if tmp.end_with? end_delim
                tmp = tmp[0..-2]
                out << tmp
                next
            end
            count += 1
            seg = ss[count]

        end
    else
        out << ss
        count += 1
    end
end

require 'pp'
pp out
