$template =<<EOL
_ _ _ _ # _ _ _ _ _ _ _ _ _ # _ _ _ _

_ # _ # _ # _ # _ # _ # _ # _ # _ # _

_ _ _ _ _ _ _ _ _ # _ _ _ _ _ _ _ _ _

_ # _ # _ # _ # _ _ _ # _ # _ # _ # _

# _ _ _ _ # _ # _ # _ # _ # _ _ _ _ #

_ # _ # # # _ _ _ _ _ _ _ # # # _ # _

_ _ _ _ _ _ # # _ # _ # # _ _ _ _ _ _

_ # _ # # _ # _ _ _ _ _ # _ # # _ # _

_ _ _ _ _ _ _ _ # _ # _ _ _ _ _ _ _ _

_ # # _ # _ # _ _ _ _ _ # _ # _ # # _

_ _ _ _ _ _ _ _ # _ # _ _ _ _ _ _ _ _

_ # _ # # _ # _ _ _ _ _ # _ # # _ # _

_ _ _ _ _ _ # # _ # _ # # _ _ _ _ _ _

_ # _ # # # _ _ _ _ _ _ _ # # # _ # _

# _ _ _ _ # _ # _ # _ # _ # _ _ _ _ #

_ # _ # _ # _ # _ _ _ # _ # _ # _ # _

_ _ _ _ _ _ _ _ _ # _ _ _ _ _ _ _ _ _

_ # _ # _ # _ # _ # _ # _ # _ # _ # _

_ _ _ _ # _ _ _ _ _ _ _ _ _ # _ _ _ _
EOL

$dict = File.open("wordlist.txt"){|f|f.read.upcase.split(/\n/)}

class Array
  ###This version only works for down and left-to-right, but
  ###for this quiz I don't care.
  ###Also not really a line if not at a 0, -45, or -90 degree angle; again, it doesn't matter
  def each_in_line(y1,x1,y2,x2, &block)
    until x1==x2 and y1==y2
      block.call *([self[y1][x1],y1,x1][0...block.arity])
      x1 += 1 unless x1==x2
      y1 += 1 unless y1==y2
    end
  end
  
  def deep_dup
    self.dup.map do |el|
      if el.is_a? Array
        el.deep_dup
      else
        el.dup
      end
    end
  end
end

###Assumes crossword is rectangular
###Returns an array of arrays, each containing an array with the start and end y and x
###of a section of the crossword to be filled
def word_queue(crossword)
  queue = []
  crossword.each_with_index do |row, y|
    #"|" is just a spacer; preserving hashes eases computing x index
    words = row.join.gsub('#','|#|').squeeze('|').split('|')
    words.each_with_index do |word, n|
      next if word.length == 1
      next unless word.include? '_' #For EC 1
      queue << [[y,words[0...n].join.length],[y,words[0..n].join.length]]
    end
  end
  
  crossword[0].each_index do |x|
    words = crossword.map{|row|row[x]}.
      join.gsub('#','|#|').squeeze('|').split('|')
    words.each_with_index do |word, n|
      next if word.length == 1
      next unless word.include? '_' #For EC 1
      queue << [[words[0...n].join.length, x],[words[0..n].join.length,x]]
    end
  end
  queue
end

def crossword_solution(crossword, queue=word_queue(crossword))
  return crossword if queue.empty?
  word_coords = queue.first
  word_space = ""
  crossword.each_in_line(*word_coords.flatten) {|c|word_space << c}
  regex = Regexp.new("^%s$" % word_space.gsub('_','\w'))
  possible_words = $dict.select{|w| w =~ regex}.sort_by{rand}
  until possible_words.empty?
    crossword_copy = crossword.deep_dup
    word_arr = possible_words.shift.split(//)
    crossword_copy.each_in_line(*word_coords.flatten) do |el,y,x|
      crossword_copy[y][x] = word_arr.shift
    end
    solved=crossword_solution(crossword_copy,queue-[word_coords])
    return solved if solved
  end
  nil
end

puts crossword_solution($template.chomp.gsub(' ','').
  gsub("\n\n","\n").split(/\n/).map{|s|s.split(//)}).
    map{|r|r.join}.join("\n").tr('#',' ')
                