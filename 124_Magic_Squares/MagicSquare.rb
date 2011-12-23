 def magic_square(n)
   square = [].fill(nil,0...n).map{
     [].fill(nil,0...n)}
   x,y = (n-1)2, 0
   nxt = 1
   while nxt = n2
     square[y][x] = nxt
     nxt += 1
     if square[(y-n-1)%n][(x+n+1)%n]
       y += 1
     else
       x,y, = (x+n+1)%n,(y-n-1)%n
     end
   end
   square
 end

 n = ARGV[0].to_i
 digits = (n2).to_s.length
 square = magic_square(n)
 square.map! {arr arr.map{x   (digits - x.to_s.length) + # 
 {x}}}
 n.times {t
   puts + + (-  (n(digits + 3)-1)) + +
   puts  #{square[t].join('  ')} }
 puts + + (-  (n(digits + 3)-1)) + +