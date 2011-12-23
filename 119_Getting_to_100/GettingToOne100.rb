   require 'enumerator'
  
   class InsertedOperatorExpression
     attr_accessor :value, :expression
  
     def initialize(numbers, operators, operatorPlacement)
       @numbers = numbers
       @operators = [].fill(nil, 0, numbers.length - 1)
       operatorPlacement.each_index {|x| @operators[operatorPlacement 
   [x]] = operators[x]}
       @expression = @numbers.zip(@operators).flatten.join
       @value = eval(@expression.gsub(/(\d)([+-\/*%^])/, '\1.0\2').gsub 
   (/\^/,'**')) # first gsub needed to prevent integer division
     end
  
     def to_s
       @expression + "=" + @value.to_s
     end
  
     def hash #Needed for uniq
       @expression.hash
     end
  
     def eql?(other) #Needed for uniq
       @expression == other.expression
     end
   end
  
   def findExpression(nums, ops, target)
     opPlacements = allPlacements(ops.length, (0...(nums.length -  
   1)).to_a)
     allExpressions = opPlacements.map {|placement|  
   InsertedOperatorExpression.new(nums,ops, placement)}.uniq
       allExpressions.each do |expression|
       puts "******************************" if expression.value ==  target
       puts expression
       puts "******************************" if expression.value ==  
       target
     end
     puts "%d possible equations tested" % allExpressions.length
   end
  
   def allPlacements(remaining, avail, already=[])
     return [already] if remaining == 0
     avail.enum_for.inject([]) {|placements, spot|
         placements + allPlacements( remaining - 1, avail - [spot],  
   already + [spot])}
   end
  
  
   puts "Enter number sequence"
   nums = gets.chomp.split(//).map {|c| c.to_i}
   puts "Enter allowable operators (+-*/%^)"
   ops = gets.chomp.split(//).map {|c| c.to_sym}
   puts "Enter target value"
   target = gets.chomp.to_f
   findExpression(nums, ops, target)