$Words = (file=File.new("words.txt")).read.upcase.split(/\n/)
file.close
def hangman_start
 puts "Please enter word pattern."
 word_pattern = gets.chomp
 possible_words = []
 word_pattern.split.length.times do |t|
  possible_words << $Words.select{ |word|
   word_pattern.split[t].length == word.length}
 end
 
 hangman_round word_pattern, possible_words
end
$avail_letters= ("A".."Z").to_a
def hangman_round(word_pattern, possible_words, lives=6)
 guess(word_pattern, possible_words)
 puts word_pattern
 puts "Are there any #{$guess}s?\t\tComputer lives=#{lives}"
 if gets.chomp=="y"
  puts "Please indicate all positions with a #{$guess}"
  puts "(0-indexed, comma-delimited)"
  gets.chomp.split(/,/).each{|pstr| word_pattern[pstr.to_i] = $guess}
  possible_words.each_index do |i|
   possible_words[i] = possible_words[i].select{|word| 
    word.gsub(/[^#{$guess}]/, '_') == 
     word_pattern.split[i].gsub(/[^#{$guess}]/, '_')}
  end
 else
  lives -= 1
  possible_words.each {|words| words.reject! {|word| word.index $guess}}
 end
 if word_pattern !~ /_/
  puts word_pattern
  puts "I win"
 elsif lives > 0
  hangman_round(word_pattern, possible_words, lives)
 else
  puts "You win"
 end
end
#Guesses by frequency analysis. If a letter appears in a possible word, it's a vote for
#that letter. If a word is possible more than once, that's multiple votes, but not
#if the letter appears multiple times in a possible word (it's still one possibility)
#It then removes that letter from $avail_letters and stores the guess into $guess
#for convenience
def guess(word_pattern, possible_words)
 all_words = possible_words.flatten
 guess = $avail_letters.sort_by {|c|
  all_words.select{|w|w.index c}.length}.last
 $avail_letters -= [guess]
 $guess = guess
end
hangman_start