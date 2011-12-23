require 'enumerator'
require 'RMagick'

DESIRED_FITNESS = 1.05
GENERATION_SIZE = 30


# Square grid (order n**2, where n is an integer > 1). Grid points are
# spaced on the unit lattice with (0, 0) at the lower left corner and
# (n-1, n-1) at the upper right.

class Grid
  attr_reader :n, :pts, :min
  def initialize(n)
    raise ArgumentError unless Integer === n && n > 1
    @n = n
    @pts = []
    n.times do |i|
      x = i.to_f
      n.times { |j| @pts << [x, j.to_f] }
    end
    # @min is length of any shortest tour traversing the grid.
    @min = n * n
    @min += Math::sqrt(2.0) - 1 if @n & 1 == 1
  end
end

class Array
  def conses(size)
    conses = []
    each_cons(size) do |cns|
      conses << cns
    end
    conses
  end
end

def rand_sorted_nums(n, max)
  ([nil]*n).map{rand(max)}.sort
end

###Asexual recombinators

##The 'exchange' recombinator mentioned in the quiz description.
##Splits itinerary into four segments based on three points and swaps the middles
def adjacent_segment_swap(itin)
  i1,i2,i3 = rand_sorted_nums(3, itin.length)
  itin[0...i1] + itin[i2..i3] + itin[i1...i2] + itin[(i3+1)..-1]
end

##Like adjacent_segment_swap, but splits into 5 segments and swaps 2 and 4
def nonadjacent_segment_swap(itin)
  i1,i2,i3,i4 = rand_sorted_nums(4, itin.length)
  i1,i2,i3,i4 = rand_sorted_nums(4, itin.length) until i2 != i3
  itin[0...i1] + itin[i3..i4] + itin[(i2+1)...i3] + itin[i1..i2] +
      itin[(i4+1)..-1]
end

##The reverse recombinator mentioned in the quiz description
##Splits itinerary into three segments based on two points;
##reverses the nodes in the middle
def reverse_segment(itin)
  i1,i2 = rand_sorted_nums(2, itin.length)
  itin[0...i1] + itin[i1..i2].reverse + itin[(i2+1)..-1]
end

##Simply swaps a random two nodes
def element_swap(itin)
  i1, i2 = rand_sorted_nums(2, itin.length)
  itin_chld = itin.dup
  itin_chld[i1], itin_chld[i2] = itin_chld[i2], itin_chld[i1]
  itin_chld
end

##Splits into three segments based on two points.
##Every adjacent pair in the middle segment is swapped. E.g.: [a,b,c,d,e] -> [b,a,d,c,e]
def adjacent_el_swap(itin)
  i1,i2 = rand_sorted_nums(2, itin.length)
  itin_chld = itin[0...i1]
  itin[i1..i2].each_slice(2) do |a,b|
    itin_chld += [b,a].compact
  end
  itin_chld + itin[(i2+1)..-1]
end

###Sexual recombinators

##Described in Wikipedia's article on crossovers in genetic algorithms
##Splits female into three segments based on two points. Reorders middle according
##to the order of the nodes in the male
def partner_guided_reorder(itinf, itinm)
  i1,i2 = rand_sorted_nums(2, itinf.length)
  itinf[0...i1] +
    itinf[i1..i2].sort_by{|el| itinm.index(el)} +
      itinf[(i2+1)..-1]
end

##Identifies segments of the male itinerary (genes) that are maximally fit.
##Reorders the corresponding nodes in the female to match
def fit_gene_exchange(itinf, itinm)
  gene_length = rand(Math.sqrt($grid.n).floor) + 1
  return itinf if 2..($grid.pts.length) === gene_length
  genes = []
  itinm.each_cons(gene_length) do |cns|
    genes << cns
  end
  genes.map! {|gene| [total_driving_distance(gene), gene]}
  genes.sort!
  
  itin_chld = itinf.dup
  genes.each do |(dist, gene)|
    break if dist > gene_length
    break if rand(10) == 0
    
    gene[1..-1].each do |node|
      itin_chld.slice!(itin_chld.index(node))
    end
    p [gene_length, gene]
    itin_chld[itin_chld.index(gene.first)] = gene
  end
  itin_chld
end

RECOMBINATORS = [:adjacent_segment_swap,
                            :nonadjacent_segment_swap,
                            :reverse_segment,
                            :element_swap,
                            :adjacent_el_swap,
                            :partner_guided_reorder,
                            :fit_gene_exchange,
            ].map{|sym| method(sym)}

###End of genetic recombinators

def total_driving_distance(itin)
  itin.conses(2).inject(0) {|dist, ((x1,y1),(x2,y2))|
    dist+Math.sqrt(((y2-y1)**2)+((x2-x1)**2))}
end
  
def fitness(itin)
  total_driving_distance(itin + [itin.first]) #Must return to starting point
end

def next_generation(parents, target_size)
  (parents * (target_size / parents.length + 1))[0..target_size].map do |par|
    recom = RECOMBINATORS[rand(RECOMBINATORS.size)]
    if recom.arity == 1
      v=recom.call(par)
    else
      v=recom.call(par,parents[rand(parents.size)])
    end
    puts recom if v.size != $grid.pts.size
    v
  end
end

def  genetic_search(initial_population)
  pop = initial_population
  until fitness(pop.first) <= $grid.min * DESIRED_FITNESS
    pop = next_generation(pop, GENERATION_SIZE * 3).
      sort_by{|itin| fitness(itin)}[0...GENERATION_SIZE]
  end
  pop.first
end


SPACING = 50
BORDER = 20
def draw_itin(itin, filename)
  dim = ($grid.n-1)*SPACING + BORDER * 2
  canvas = Magick::Image.new(dim, dim)
  gc = Magick::Draw.new
  gc.stroke('black')
  gc.stroke_width(1)
  
  $grid.pts.each do |(x,y)|
    gc.circle(*[x,y,x+3.0/SPACING, y].map{|c|c*SPACING+BORDER})
  end
  (itin+[itin.first]).each_cons(2) do |((x1,y1),(x2,y2))|
    gc.line(*[x1,y1,x2,y2].map{|c|c*SPACING+BORDER})
  end
  gc.draw(canvas)
  canvas.write(filename)
end

n = ARGV[0].to_i
$grid = Grid.new(n)
init_pop = next_generation([$grid.pts] * GENERATION_SIZE,
    GENERATION_SIZE)
draw_itin(genetic_search(init_pop), "#{n}x#{n}tour.jpg")