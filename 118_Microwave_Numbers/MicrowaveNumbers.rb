buttons = ['1','2','3',
                '4','5','6',
                '7','8','9',
                nil,'0','*']
  
   $w = 1
   $h = 1
  
   def microwave(seconds, tolerance)
     combinations = []
     low = [seconds - tolerance, 0].max
     high = seconds + tolerance
     Range.new(low,high).each do |t|
       combinations << ((t / 60).floor.to_s + (t % 60).to_s.sub(/^ 
   ([0-9])$/, '0\1') + '*')
       combinations << ((t / 60 - 1).floor.to_s + (t % 60 + 60).to_s +  
   '*') if t % 60 < 40
     end
     combinations.collect! {|c| c.gsub(/^0/,"")}
     efficiency = combinations.collect {|comb| computeTotalDistance 
   (comb)}
     combinations[efficiency.index(efficiency.min)]
   end
  
   def computeTotalDistance(comb)
     distance = 0
     lastChar = nil
     comb.each_char do |c|
       distance += computeDistance(lastChar + c) if lastChar
       lastChar = c
     end
     distance
   end
  
   def computeDistance(comb)
     c1, c2 = comb[0,1], comb[1,1]
     x1, y1 = $buttons.index(c1) % 3 * $w, ($buttons.index(c1) /  
   3).floor * $h
     x2, y2 = $buttons.index(c2) % 3 * $w, ($buttons.index(c2) /  
   3).floor * $h
     ((x2 - x1) ** 2 + (y2 - y1) ** 2) ** 0.5
   end
  
   puts "Enter number of seconds to microwave, followed by the tolerance"
   puts "The most efficient key-pattern is " + microwave 
   (gets.chomp.to_i, gets.chomp.to_i)