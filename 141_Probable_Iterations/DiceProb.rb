DES_NUMBER = 5
DICE_SIDES = 6

verbose = ARGV.include? "-v"
sample = ARGV.include? "-s"

dice = ARGV[-2].to_i
min_des = ARGV[-1].to_i

pos_outcomes = DICE_SIDES ** dice
des_outcomes = 0

max_digits = pos_outcomes.to_s.size

state = [1]*dice

1.upto(pos_outcomes) do |i|
  des_outcomes += 1 if state.select{|x|1==x}.size >= min_des
  puts "%#{max_digits}d    %s" % [i, state.inspect] if
    verbose or sample && i % 50000 == 1
  state[0] += 1
  break if i == pos_outcomes
  state.each_with_index do |n, idx|
    if n > DICE_SIDES
      state[idx] = 1
      state[idx+1] += 1
    end
  end
end

print "\n\n"
puts "Number of desirable outcomes is #{des_outcomes}"
puts "Number of possible outcomes is #{pos_outcomes}\n"
puts "Probability is #{des_outcomes.to_f/pos_outcomes}"