class Vector
  def distance(oth)
    Math.sqrt(to_a.zip(oth.to_a).inject(0){|s,(a,b)|s+(a-b)**2})
  end
end

class Triangle
  def area
    ab  a.distance(@b)
    bc  b.distance(@c)
    ac  a.distance(@c)
    s  ab+bc+ac)/2
    Math.sqrt(s*(s-ab)*(s-bc)*(s-ac))
  end
end