
class Hash
  def inverse
    h = Hash.new
    each_pair {|key, value| h[value] = key}
    h
  end
  
  def map_pair
    h = Hash.new
    each_pair {|key, value| h[key] = yield key, value}
    h
  end
  
  def map_value
    map_pair {|key, value| yield value}
  end
  
  alias + merge!
end
  
  $orientations = {:up => 0,
                           :right => 1,
                           :down => 2,
                           :left => 3}
  
  $offsets = {:up_right =>1,
                        :down_right =>3,
                        :down_left =>-3,
                        :up_left => -1,
                        :up =>0,
                        :right =>2,
                        :down =>4,
                        :left =>-2}
  
  $rotations = {:up_right => :down_right,
                        :down_right => :down_left,
                        :down_left => :up_left,
                        :up_left => :up_right,
                        :up => :right,
                        :right => :down,
                        :down =>  :left,
                        :left => :up}
  
  $direction_meanings = {:up_right => [-1,1],
                               :down_right => [1, 1],
                               :down_left => [1,-1],
                               :up_left => [-1,-1],
                               :up => [-1, 0],
                               :left => [0,-1],
                               :right => [0, 1],
                               :down => [1,0]}
  
  def direction_rotated(n,dir)
    n.times {dir = $rotations[dir]}
    dir
  end

class FractalNode
  
  #Methods for creating fractals in blocks

  attr_writer :orientation, :offset, :parent, :children
 
  def method_missing(mID, *args)
    if args.empty?
      instance_variable_get("@#{mID}".to_sym)
    else
      send("#{mID}=",args.first)
    end
  end
  
  def child(&block)
    @children << FractalNode.new(&block)
    @children.last.parent = self
  end
  
  def initialize(&block)
    @children = []
    @parent = nil
    @offset = nil
    instance_eval &block
  end
  
  #Methods needed to expand fractals
  
  alias old_dup dup
  def dup
    new = old_dup
    children.each{|c| c.parent = new}
    new
  end
  
  def rotate_offset!(n)
    @offset = direction_rotated(n, offset)
    self
  end
  
  def rotate!(n)
    @orientation =
      $orientations.inverse[(n+$orientations[@orientation])%4]
    self
  end

  def rotate_offset(n)
    self.dup.rotate_offset!(n)
  end
  
  def rotate(n)
    self.dup.rotate!(n)
  end
  
  def deep_rotate(n)
    newNode = rotate(n).rotate_offset!(n)
    newNode.children = newNode.children.map {|c| c.deep_rotate(n)}
    newNode
  end
  
  def follow_branch(direction)
    return self if children.empty?
    adjustment = 4-$offsets[direction]/2
    children.sort_by{|c|
      ($offsets[direction_rotated(adjustment, direction)] -
        $offsets[direction_rotated(adjustment, c.offset)]).abs
    }.first.follow_branch(direction)
  end

  def hierarchial_correct!(parent=nil)
    if parent != @parent
      @children << @parent if @parent
      @children -= [parent]
    end
    @children.each {|child| child.hierarchial_correct!(self)}
    unless parent == @parent
      if parent
        @offset = direction_rotated(2,parent.offset)
      else
        rotate_offset!(2)
      end
    end
    @parent = parent
  end    
  
  def fractal_expand(replacement)
    my_replacement = replacement.deep_rotate($orientations[orientation])
    top = nil
    if offset
      top = my_replacement.follow_branch(direction_rotated(2,offset))
    else
      top = my_replacement
    end
    top.hierarchial_correct!
    top.offset = offset
    children.each {|child|
      my_replacement.follow_branch(child.offset).children = [child.fractal_expand(replacement)]}
    top
  end
  
  #Methods used to print fractals
  
  def relative_coordinates
    coord_hash = {self => [0,0]}
    children.each do |child|
        branch_coords = child.relative_coordinates
        branch_offset = $direction_meanings[child.offset]
        coord_hash += branch_coords.map_value { |val|
          val.zip(branch_offset).map{|c, c_off| c+c_off}}
    end
    coord_hash
  end
  
  def direction_most(direction)
    y_weight, x_weight = $direction_meanings[direction]
    
    relative_coord_mappings = relative_coordinates
    relative_coords = relative_coord_mappings.values.sort_by {|y,x|
      y*y_weight + x*x_weight}
    relative_coord_mappings.inverse[relative_coords.last]
  end
  
  def vertical?
    @orientation == :left or @orientation == :right
  end
  
  def horizontal?
    !vertical?
  end
  
  require 'enumerator'
  def print_fractal(f=$stdout)
    coord_mappings = relative_coordinates
    highest = direction_most(:up)
    min_y = coord_mappings[highest][0]
    min_y -= 1 if highest.horizontal?
    max_y = coord_mappings[direction_most(:down)][0]
    min_x = coord_mappings[direction_most(:left)][1]
    max_x = coord_mappings[direction_most(:right)][1]
    fractal_rep_arr = [].fill(nil, max_y-min_y)
    0.upto(max_y-min_y) {|r| fractal_rep_arr[r] = [].fill(nil, 0..(max_x - min_x))}
    coord_mappings.each_pair { |node,( y, x)| fractal_rep_arr[y-min_y][x-min_x] = node}
    fractal_rep_arr << [].fill(nil,0,max_x) unless fractal_rep_arr.length % 2 == 0
    fractal_rep_arr.each_slice(2) do |row_v, row_h|
      row_v.zip(row_h).map{|a| a == [nil,nil] ? [nil] : a.compact}.flatten.each do |n|
        if n.nil?
          f.print ' '
          next
        end
        f.print '|' if n.vertical?
        f.print '_' if n.horizontal?
      end
      f.puts
    end
  end
end

def fractal_level(n,replacement)
  fractal = $starting_fractal    
  n.times {fractal = fractal.fractal_expand(replacement.deep_rotate(4-$orientations[replacement.orientation]))}
  fractal.deep_rotate($orientations[replacement.orientation])
end

#The following figure
#_
$starting_fractal = FractalNode.new do
  orientation :up
end

#The following figure
#  _
#_| |
#$starting_fractal = FractalNode.new do
#    orientation :up
#    child do
#      orientation :right
#      offset :down_right
#    end
#    child do
#      orientation :left
#      offset :down_left
#      child do
#        orientation :down
#        offset :down_right
#      end
#    end
#  end

#The following figure
# _
#| |
#$starting_fractal = FractalNode.new do
#    orientation :up
#    child do
#      orientation :right
#      offset :down_right
#    end
#    child do
#     orientation :left
#     offset :down_left
#    end
#end

#The following figure
#   _
#_| |_
#standard_fractal = FractalNode.new do
#  orientation :up
#  child do
#    orientation :right
#    offset :down_right
#   child do
#     orientation :up
#     offset :down_right
#   end
#  end
# child do
#    orientation :left
#    offset :down_left
#    child do
#      orientation :up
#      offset :down_left
#   end
#  end
#end

#The following figure
#  _
#_|
standard_fractal = FractalNode.new do
  orientation :down
  child do
    orientation :left
    offset :up_right
    child do
      orientation :down
      offset :up_right
    end
  end
end

#The following figure
#_   _
# |_|
#_| |_
#standard_fractal = FractalNode.new do
#  orientation :up
#  child do
#   orientation :right
#   offset :down_right
#   child do
#      orientation :up
#      offset :down_right
#   end
#  end
# child do
#   orientation :left
#   offset :down_left
#   child do
#      orientation :up
#      offset :down_left
#   end
#  end
# child do
#   orientation :left
#   offset :up_left
#   child do
#      orientation :down
#      offset :up_left
#   end
#  end
# child do
#   orientation :right
#   offset :up_right
#   child do
#      orientation :down
#      offset :up_right
#   end
#  end
#end

#The following figure
# _
#| |
#standard_fractal = FractalNode.new do
#    orientation :up
#    child do
#      orientation :right
#      offset :down_right
#    end
#    child do
#      orientation :left
#      offset :down_left
#    end

#THIS IS THE ONE THAT DOESN'T WHOLLY WORK
#The following figure
#      _      
#    _| |_    
#  _|_   _|_  
#    _| |_    
#  _|     |_  
#_|         |_
#standard_fractal = FractalNode.new do
#  orientation :up
#  child do
#    orientation:left
#    offset :down_left
#    child do
#      orientation :up
#      offset :down_left
#      child do
#        orientation:left
#        offset :down_left
#        child do
#          orientation :up
#          offset :down_left
#        end
#        child do
#          orientation :up
#          offset :down_right
#          child do
#            orientation :right
#            offset :down_right
#            child do
#              orientation :down
#              offset :down_left
#              child do
#                orientation :right
#                offset :down_left
#                child do
#                  orientation :down
#                  offset :down_left
#                  child do
#                    orientation :right
#                    offset :down_left
#                    child do
#                      orientation :down
#                      offset :down_left
#                    end
#                  end
#                end
#              end
#            end
#          end
#        end
#      end
#    end
#  end
#  child do
#    orientation:right
#    offset :down_right
#    child do
#      orientation :up
#      offset :down_right
#      child do
#        orientation:right
#        offset :down_right
#        child do
#          orientation :up
#          offset :down_right
#        end
#        child do
#          orientation :up
#          offset :down_left
#          child do
#            orientation :left
#            offset :down_left
#            child do
#              orientation :down
#              offset :down_right
#              child do
#                orientation :left
#                offset :down_right
#                child do
#                  orientation :down
#                  offset :down_right
#                  child do
#                    orientation :left
#                    offset :down_right
#                    child do
#                      orientation :down
#                      offset :down_right
#                    end
#                  end
#                end
#              end
#            end
#          end
#        end
#      end
#    end
#  end
#end

#The following figure:
#__
#standard_fractal = FractalNode.new do
#  orientation :up
#  child do
#    orientation :up
#    offset :right
#  end
#end

#File.open("fractal.txt", "w") {|f|
  fractal_level(ARGV[0].to_i, standard_fractal).print_fractal#(f)}