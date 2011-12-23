   class Array
     def map_with_index
       each_with_index { |el, i|
         self[i] = yield el, i}
     end
   end
  
   #Contains the card types keyed by regular
   #expressions that match said card types
   $cardTypes = {/^3[47]\d{13}$/ => "AMEX",
                 /^6011\d{12}$/ => "Discover",
                 /^5[1-5]\d{14}$/ => "MasterCard",
                 /^4\d{12}(\d{3})?$/ => "Visa"}
  
   #Returns the card type
   def cardType(cardNumber)
     $cardTypes.each_key {|format|
       return $cardTypes[format] if cardNumber =~ format}
     "Unknown"
   end
  
   require 'enumerator'
  
   #Returns whether it passes Luhn validation
   def luhn?(cardNumber)
     cardNumber.split(//).map_with_index do |el, i|
       #1)Starting with the next to last digit
       #and continuing with every other
       #digit going back to the beginning of the card, double the digit
       #
       #This means that, if the length is even, even indices
       #are doubled, and vice versa
       if i % 2 == cardNumber.length % 2
         #Doubled digits will have to be split again
         (el.to_i * 2).to_s.split(//).map{|n| n.to_i}
      else
         el.to_i
       end
     #2) Sum all numbers
     end.flatten.enum_for.inject(0){|sum, num|sum + num } %
     #3)Check for multiple of 10
     10 == 0
   end
  
   ARGV.each do |arg|
     puts cardType(arg)
     #1-line way of converting booleans to words
     puts ({false => "Invalid", true => "Valid"}[luhn?(arg)])
   end