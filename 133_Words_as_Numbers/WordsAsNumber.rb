dict = File.open("wordlist.txt"){|f| f.readlines.reject {|word|
  ('A'..'Z') === word[0,1]}}

base = ARGV[0].to_i

puts dict.select{|word| word.unpack("C*").select{|char|
  char > ?a+base-11}.empty?}