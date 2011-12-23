#$thesaurus = File.open("mobythes.aur") do |f|
#  h = Hash.new
#  f.readlines.each do |line|
#    words=line.chomp.split(',').map{|s|s.upcase}
#    h[words[0]] = words[1..-1]
#  end
#  h
#end

#This only works if the beginning comments are manually removed
$pronunciations = File.open("cmudict0.3") do |f|
  NUMBER_OF_SYMBOLS = 39
  
  h = Hash.new
  
  lines = f.readlines
  lines[0...NUMBER_OF_SYMBOLS].each do |line|
    h[lines[0...(line =~ /[A-Z]/)]] = line.split[1..-1]
  end
  lines[NUMBER_OF_SYMBOLS..-1].each do |line|
    words = line.split(/\s+/)
    h[words.first] = words[1..-1]
  end
  h
end

$words = $pronunciations.keys

#See http://en.wikipedia.org/wiki/Levenshtein_distance#The_algorithm
def levenshtein_distance(a, b)
  prev_row = (0..b.length).to_a
  cur_row = [0] * b.length
  1.upto(a.length) do |i|
    cur_row[0] = i
    1.upto(b.length) do |j|
      cost = (a[i-1] == b[j-1]) ? 0 : 1
      cur_row[j] = [prev_row[j]+1,
                          cur_row[j-1]+1,
                          prev_row[j-1]+cost].min
                        end
    prev_row = cur_row
    cur_row = cur_row.dup
  end
  prev_row.last
end


#def all_synonym_combinations(word_arr)
# if word_arr.size == 1
#   ($thesaurus[word_arr.first] || [word_arr.first]).map{|w|[w]}
# else
#   next_combs = all_synonym_combinations(word_arr[1..-1])
#   next_combs_length = next_combs.flatten.length
#   synonyms = ($thesaurus[word_arr[0]] || []) << word_arr[0]
#   synonyms = synonyms.inject([]){|a,w| a+=[[w]]*next_combs_length}
#   synonyms.flatten.zip(next_combs*synonyms.length
#     ).map{|a|a.flatten}
# end
#end

rebus = ARGV[0].chomp

expressions = rebus.scan(/(?:\().+?(?:\))/)

expressions.each do |expression|
  
  ops = expression.scan(/[+-]/)
  terms = expression.gsub(/[\(\)]/,"").scan(/[^+-]+/)
  #all_synonym_combinations(terms).each do |terms|
    pronunciation = $pronunciations[terms[0]]
    terms[1..-1].each_with_index do |term,idx|
      if ops[idx] == "+"
        pronunciation += $pronunciations[term]
      else
        #Set difference is a very crude interpretation of subtraction in rebuses
        #(especially considering, in cmudict, a letter's pronunciation is that
        #           of its name, not its main phoneme)
        pronunciation -= $pronunciations[term]
      end
    end
    reps = $words.sort_by{|word|
      levenshtein_distance($pronunciations[word],
        pronunciation)}
    rep = terms.index(reps[0]) ? reps[1] : reps[0]
    rebus[expression] = rep
  #end
end

puts rebus.gsub("+"," ")