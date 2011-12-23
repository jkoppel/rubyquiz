def find_solution(expr)
  expr = expr.sub('=','==')
  chars = []
  expr.scan(/./){|c| chars |= [c] unless "*/%+-()=".include? c}
  solution_helper chars, expr
end

def solution_helper(rem_chars, expr, rem_nums=(0..9).to_a,
    char_reps={})
  if rem_chars.empty?
    return eval(expr.gsub(/./){|c|
      (char_reps.keys.include? c) ? char_reps[c] : c}) ?
      char_reps : nil
  end
  
  rem_nums.each do |n|
    next if n==0 && expr =~ /(^|[*\/%+\-(=])#{rem_chars[0]}/
    s = solution_helper(rem_chars[1..-1], expr, rem_nums - [n],
      char_reps.merge({rem_chars[0]=>n}))
    return s if s
  end
  nil
end

find_solution(ARGV[0]).each_pair do |k,v|
  puts "#{k}: #{v}"
end