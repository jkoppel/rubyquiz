#A loop is possible whenever there are two of the same lettter an even distance 
#greater than 2 from each other
def first_loop(letters)
  0.upto(letters.length-1) do |idx1|
    (idx1+4).step(letters.length-1,2) do |idx2|
      return [idx1,idx2] if letters[idx1].casecmp(letters[idx2])==0
    end
  end
  nil
end

letters = ARGV.first.split(//)

first,last = first_loop(letters)

if first==nil
  puts "No loop"
  exit
end

letters[(last+1)..-1].reverse_each {|l| puts ' '*first + l}
puts letters[0..(first+1)].join
1.upto((last-first-1)/2) do |n|
  puts ' '*first + letters[last-n] + letters[first+1+n]
end