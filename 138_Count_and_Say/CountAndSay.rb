class Integer

  def teen
    case self
    when 0: "ten"
    when 1: "eleven"
    when 2: "twelve"
    else    in_compound + "teen"
    end
  end

  def ten
    case self
    when 1: "ten"
    when 2: "twenty"
    else    in_compound + "ty"
    end
  end

  def in_compound
    case self
    when 3: "thir"
    when 5: "fif"
    when 8: "eigh"
    else    to_en
    end
  end

  def to_en(ands=true)
    small_nums = [""] + %w[one two three four five six seven eight nine]
    if self < 10: small_nums[self]
    elsif self < 20: (self % 10).teen
    elsif self < 100:
      result = (self/10).ten
      result += "-" if (self % 10) != 0
      result += (self % 10).to_en
      return result
    elsif self < 1000
      if self%100 != 0 and ands
        (self/100).to_en(ands)+" hundred and "+(self%100).to_en(ands)
      else ((self/100).to_en(ands)+
        " hundred "+(self%100).to_en(ands)).chomp(" ")
      end
    else
      front,back = case (self.to_s.length) % 3
        when 0: [0..2,3..-1].map{|i| self.to_s[i]}.map{|i| i.to_i}
        when 2: [0..1,2..-1].map{|i| self.to_s[i]}.map{|i| i.to_i}
        when 1: [0..0,1..-1].map{|i| self.to_s[i]}.map{|i| i.to_i}
        end
      degree = [""] + %w[thousand million billion trillion quadrillion 
      quintillion sextillion septillion octillion nonillion decillion
      undecillion duodecillion tredecillion quattuordecillion
      quindecillion sexdecillion septdecillion novemdecillion
      vigintillion unvigintillion duovigintillion trevigintillion
      quattuorvigintillion quinvigintillion sexvigintillion 
      septvigintillion octovigintillion novemvigintillion trigintillion 
      untregintillion duotrigintillion googol]
      result = front.to_en(false) + " " + degree[(self.to_s.length-1)/3]
      result += if back > 99: ", "
                elsif back > 0: ands ? " and " : " "
                else ""
                end
      result += back.to_en(ands)
      return result.chomp(" ")
    end
  end
end

def count_and_say(str)
  ('A'..'Z').map{|l| (str.count(l) > 0) ? 
    [str.count(l).to_en.upcase, l] : ""}.join(' ').squeeze(' ')
end

order = ARGV[0].chomp.to_i
prev_results = {}
element = "LOOK AND SAY"
for n in (0..order)
  if prev_results[element]
    puts "Cycle of length #{n-prev_results[element]} starting" +
      " at element #{prev_results[element]}"
    #puts "Cycle's elements are:"
    #puts (prev_results[element]...n).to_a.map{|n| prev_results.invert[n]}
    break
  else
    prev_results[element] = n
  end
  element = count_and_say(element)
end