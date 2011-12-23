require 'profile'

class Array
  def sum
    inject(0){|s,n|s+n}
  end
end

def cartesian_product(first, *rest)
  return first if rest == []
  rest = cartesian_product(*rest)
  combs = block_given? ? nil : []
  first.each do |v1|
    rest.each do |v2|
      if block_given?
        yield v1+v2
      else
        combs << (v1 + v2)
      end
    end
  end
  combs
end

Infinity = 1.0/0
#Calculates the minimum amount of coins needed to get the amount,
#if fractions of coins were legal.
def min_size_heuristic(amount,comb,coins)
  rem = amount-comb.sum
  return Infinity if rem < 0
  comb.size+rem.to_f/(coins.select{|c|c<=rem&&c<=comb.max}.max) rescue comb.size
end

#Determines the priority of which combinations of coins to search.
#Multiplies min_size_heuristic by the distance of the amount from the current sum
def solution_proximity_heuristic(amount,comb,coins)
  (amount-comb.sum)*min_size_heuristic(amount,comb,coins)
end

def make_change(amount, coins = [25, 10, 5, 1])
  queue =coins.select{|c|c<=amount}.map{|c|[c]}.sort_by{|comb|
    solution_proximity_heuristic(amount,comb,coins)}
  
  smallest_change = nil
  until queue.empty?
    comb = queue.shift
    if comb.sum == amount
      smallest_change = comb if smallest_change.nil? or comb.size < smallest_change.size
      next
    end
    combs = cartesian_product([comb],coins.select{|c|c<=comb.last}.map{|c|[c]})
    combs.delete_if {|comb| comb.sum > amount ||
      smallest_change != nil && 
        min_size_heuristic(amount,comb,coins).ceil >= smallest_change.size}
    queue = (queue+combs).sort_by{|c|solution_proximity_heuristic(amount,c,coins)}
  end
  smallest_change  
end

ARGV.map!{|s|s.to_i}

p make_change(ARGV[0],ARGV[1] ? ARGV[1..-1] : [25,10,5,1])