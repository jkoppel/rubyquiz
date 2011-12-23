   $code = { '.-' => "A", '-...' => "B", '-.-.' => "C", '-..' => "D",
    '.' => "E", '..-.' =>     "F", '--.' => "G", '....' => "H",
    '..' => "I", '.---' => "J", '-.-' => "K", '.-..' =>     "L",
    '--' =>     "M", '-.' =>     "N", '---' => "O", '.--.' => "P",
    '--.-' =>  "Q", '.-.' => "R", '...' => "S", '-' =>     "T",
    '..-' =>     "U", '...-' => "V", '.--' => "W", '-..-' => "X",
    '-.--' => "Y", '--..' => "Z"}
  
   def printTranslations(morse, english="")
     puts english if "" == morse
     (1..[4, morse.length].min).each { |n|
       printTranslations(morse[n..-1], english + $code[morse[0,n]]) if  
   $code.has_key?(morse[0,n])}
   end
  
   puts "Input morse code string"
   printTranslations(gets.chomp)
  