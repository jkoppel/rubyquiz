#Solution #1: Array is bound to arr
 
sub_arrs = []
arr.each_index{|i| (i...arr.length).each{|i2| sub_arrs << arr[i..i2]}}
p sub_arrs.sort_by{|arr| arr.inject(0){|s,n|s+n}}.last
 
#Solution #2: Array is bound to a
 
p (b=(0...(l=a.size)).to_a).zip([b]*l).map{|(i,s)|s.map{|j|a[i,j]}}.sort_by{|a|a.map!{|a|[a.inject(0){|s,n|s+n},a]}.sort![-1][0]}[-1][-1][-1]