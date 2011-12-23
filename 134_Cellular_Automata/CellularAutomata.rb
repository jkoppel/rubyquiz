require 'enumerator'

def step(state,rule)
  cur_arr = ([0,0] + state.split(//) + [0,0]).map{|s| s.to_i}
  next_arr = []
  cur_arr.each_cons(3) do |neighborhood|
    ##Checks the (neighborhood+1)th bit of rule
    ##E.g.: If neighborhood is [0,1,0], then inserts a 1 if the third bit of rule is on
    if (2**(neighborhood.join.to_i(2)))&rule != 0
      next_arr << 1
    else
      next_arr << 0
    end
  end
  next_arr.join
end

rule = ARGV[0].chomp.to_i
steps = ARGV[1].chomp.to_i
state = ARGV[2].chomp

result = [state]

steps.times do
  state = step(state, rule)
  result << state
end

length = result.last.size

output = result.map {|row|
  ([0]*((length-row.size)/2)+row.split(//)).map{|b|
    b=="1" ? "X" : " "}.join
  }

puts output