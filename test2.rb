#!/usr/bin/env ruby

line = '79a59df900b949e55d96a1e698fbacedfd6e09d98eacf8f8d5218e7cd47ef2be mybucket [06/Feb/2014:00:00:38 +0000] 192.0.2.3 79a59df900b949e55d96a1e698fbacedfd6e09d98eacf8f8d5218e7cd47ef2be 3E57427F3EXAMPLE REST.GET.VERSIONING - "GET /mybucket?versioning HTTP/1.1" 200 - 113 - 7 - "-" "S3Console/0.4" -'
lin0 = '13784cc045aa79ecb3e164200025c7fc9205241e61ba76f40d486de657f5df52 annotationhub [19/Nov/2013:23:34:51 +0000] 140.107.151.128 - 8151DFA13868F466 REST.GET.OBJECT release-69/fasta/callithrix_jacchus/ncrna/Callithrix_jacchus.C_jacchus3.2.1.69.ncrna.fa_0.0.1.json "GET /release-69/fasta/callithrix_jacchus/ncrna/Callithrix_jacchus.C_jacchus3.2.1.69.ncrna.fa_0.0.1.json HTTP/1.1" 403 AccessDenied 231 - 7 - "-" "curl/7.30.0" -'
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
            break if 
        end
    else
        out << ss
        count += 1
    end
end

require 'pp'
pp out
