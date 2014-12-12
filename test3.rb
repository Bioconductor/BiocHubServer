#!/usr/bin/env ruby

require 'pp'

line = '79a59df900b949e55d96a1e698fbacedfd6e09d98eacf8f8d5218e7cd47ef2be mybucket [06/Feb/2014:00:00:38 +0000] 192.0.2.3 79a59df900b949e55d96a1e698fbacedfd6e09d98eacf8f8d5218e7cd47ef2be 3E57427F3EXAMPLE REST.GET.VERSIONING - "GET /mybucket?versioning HTTP/1.1" 200 - 113 - 7 - "-" "S3Console/0.4" -'

chars = line.split ""

first = true
in_delimited = false


out = []
tmp = ""

chars.each_with_index do |char, idx|
    if first
        first = false
        if ['[', '"'].include? char
            in_delimited = true
            end_delim = (char == '[') ? ']' : '"'
            next
        end
    end
    if in_delimited
        if char == end_delim
            out << tmp
            tmp = ""
            in_delimited = false
            skip = true
        else
            tmp += char
        end
    end
    if skip
        skip = false
        first = true
        next
    end
    if !in_delimited and char != " "
        tmp += char
    elsif !in_delimited and char == " "
        out << tmp
        tmp = ""
        next
    end
    if idx == (chars.length() -1)
        out << tmp
    end
end

pp out
puts out.length