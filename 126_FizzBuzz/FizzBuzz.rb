1.upto 100 do |n|
   print n unless n % 3 == 0 or n % 5 == 0
   print "Fizz" if n % 3 == 0
   print "Buzz" if n % 5 == 0
   puts
end