require 'benchmark'
puts Benchmark.measure { 100000.times {

dot_dec_ip = ARGV[0].chomp

dec_ip = dot_dec_ip[0..2].to_i << 24
dot_dec_ip = dot_dec_ip[(dot_dec_ip.index(?.)+1)..-1]
dec_ip += dot_dec_ip[0..2].to_i << 16
dec_ip += dot_dec_ip[dot_dec_ip.index(?.)+1,3].to_i << 8
#Last 8 bits are all in the same country; they don't matter

dec_ip = dec_ip

dataf = File.new("IPToCountry.csv")

###Begin binary search, finding high and low

#Hardcoded character offset of where to start. This should be the index of
#a character on the last line of comments
#
#Earlier versions used 0 or calculated this each iteration.
#The former yielded bad results (for obvious reasons);
#the latter doubled the time needed.
low = 6603

dataf.seek(0,IO::SEEK_END)
flen = dataf.pos

high = flen

while true
  if low == high - 1
    puts "IP not assigned"
    break
  end
  mid = (low + high) >> 1
  dataf.seek(mid,IO::SEEK_SET)
  dataf.gets
  dataf.getc
  range_start = dataf.gets('"')
  range_start.slice!(-1)
  range_start = range_start.to_i
  cmpno = dec_ip <=> range_start
  if cmpno == -1
    high = mid
    next
  else
    dataf.read(2)
    range_end = dataf.gets('"')
    range_end.slice!(-1)
    range_end = range_end.to_i
    if (dec_ip <=> range_end) == 1
      low = mid
      next
    else
      puts dataf.gets.match(/"(\w\w)"/)[1]
      break
    end
  end
end
}}