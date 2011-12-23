str = "RBYBGYGGYGBYBR".scan(/../).inject("") { |s, cols|
  1.upto(5) {|n|
      n2nd = s.length / 30 % 2 == 0 ? n : 6-n
      s << (cols[0,1]*(6-n2nd))+(cols[1,1]*n2nd)}
   s}

50.times {|n| puts str[n,50]}