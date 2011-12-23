class AVLTree

  include Enumerable

  # Need something smarter than nil for external nodes
  class ExternalNode
    attr_accessor :parent
    def initialize(parent)
      @parent = parent
    end
    def include?(_)    false              end
    def <<(_)          raise RuntimeError end
    def height;        0                end
    def balance_factor; 0                end
    def left;          self              end
    def right;          self              end
    def each(*args,&iter)                        end
    def left=(node)
      raise(NotImplementedError,
            "external node of #{@parent}")
    end
    def right=(node)
      raise(NotImplementedError,
            "external node of #{@parent}")
    end
    def to_s; '' end
    def to_a; [] end
  end

  class Node
    attr_accessor :data, :parent
    attr_reader :left, :right

    def initialize obj, sortblock
      @parent = nil
      @data  = obj
      @left  = ExternalNode.new(self)
      @right  = ExternalNode.new(self)
      @height = 1
      @compare = sortblock
    end

    def left=(node)
      @height = nil
      @left = node
      node.parent = self
    end

    def right=(node)
      @height = nil
      @right = node
      node.parent = self
    end

    def each(returns=:data,&iter)
      @left.each(&iter)
      iter[self.send(returns)]
      @right.each(&iter)
    end
    
    def node
      self
    end

    def height
      @height || ( [ @left.height, @right.height ].max + 1)
    end

    def << node
      case @compare[node.data,@data]
      when -1
        if Node === @left
          @left << node
        else
          self.left = node
        end
      when 0
        return self            # no dups
      when +1
        if Node === @right
          @right << node
        else
          self.right = node
        end
      end
      rebalance if balance_factor.abs > 1
      @height = nil
    end

    def remove obj
      @height = nil
      case @compare[obj,@data]
      when -1
        if Node === @left
          @left.remove(obj)
        else
          nil
        end
      when 0
        if Node === @left
          largest = nil
          AVLTree.new(@left).each(:node) do |n|
            largest = n if largest.nil? or n.data > largest.data
            largest = n if largest.nil? or n.data > largest.data
          end
          self.data = largest.data
          self.left = largest.left
        elsif Node === @right
          smallest = nil
          AVLTree.new(@right).each(:node) do |n|
            smallest = n if smallest.nil? or n.data < smallest.data
            smallest = n if smallest.nil? or n.data < smallest.data
          end
          self.data  = smallest.data
          self.right = smallest.right
        else
          parent.send :replace_child, self, ExternalNode.new(parent)
        end
        path = self
        while Node === (path = path.parent)
          path.rebalance if path.balance_factor.abs > 1
        end
        self
      when +1
        if Node === @right
          @right.remove(obj)
        else
          nil
        end
      end
    end

    def include? obj
      case obj <=> @data
      when -1 : @left.include?(obj)
      when  0 : true
      when +1 : @right.include?(obj)
      end
    end

    def to_a
      result = @left.to_a
      result << @data
      result.concat @right.to_a
      result
    end

    def [](idx)
        if idx < (leftheight = @left.height)
          @left[idx]
        elsif (idx== leftheight)
          @data
        elsif (idx-=(leftheight+1)) < @right.height
          @right[idx]
        end
    end

    def to_s
      bf = case balance_factor <=> 0
            when -1 : '-' * -balance_factor
            when  0 : '.'
            when  1 : '+' * balance_factor
            end
      "[#{left} "+
        "(#{@data}{#{height}#{bf}}^#{parent.data})"+
        " #{right}]"
    end

    protected

    def balance_factor
      @right.height - @left.height
    end

    def rotate_left
      my_parent, from, to = @parent, self, @right
      temp = @right.left
      @right.left = self
      self.right = temp
      my_parent.send :replace_child, from, to
      to.parent = my_parent
    end

    def rotate_right
      my_parent, from, to = @parent, self, @left
      temp = @left.right
      @left.right = self
      self.left = temp
      my_parent.send :replace_child, from, to
      to.parent = my_parent
    end

    def rebalance
      if (bf = balance_factor) > 1 # right is too high
        if @right.balance_factor < 0
          # double rotate right-left
          # - first the right subtree
          @right.rotate_right
        end
        rotate_left            # single rotate left
      elsif bf < -1            # left must be too high
        if @left.balance_factor > 0
          # double rotate left-right
          # - first force left subtree
          @left.rotate_left
        end
        rotate_right            # single rotate right
      end
    end

    def replace_child(from, to)
      if from.eql? @left
        @left = to
      elsif from.eql? @right
        @right = to
      else
        raise(ArgumentError,
              "#{from} is not a branch of #{self}")
      end
    end

  end

  def initialize(root = nil, &block)
    @root = root
    if block
      raise(ArgumentError,
        "Block argument for #{self.class.name} must" +
        " take 2 arguments and act as sort function"
        ) unless block.arity == 2
    else
      block = proc{|a,b| a<=>b}
    end
    @compare = block
  end

  def empty?
    @root.nil?
  end

  def include?(obj)
    empty? ? false : @root.include?(obj)
  end

  def <<(obj)
    raise(ArgumentError,
          "Objects added to #{self.class.name} must" +
          " respond to <=>"
          ) unless obj.respond_to?(:<=>)

    if empty?
      @root = Node.new(obj, @compare)
      @root.parent = self
    else
      @root << Node.new(obj, @compare)
    end
    self
  end

  def remove(obj)
    @root.remove(obj) unless empty?
  end

  def height
    empty? ? 0 : @root.height
  end

  def [](idx)
    @root[idx]
  end

  def to_a
    empty? ? [] : @root.to_a
  end

  def each(*args,&iter)
    @root.each(*args,&iter) unless empty?
  end

  def to_s
    empty? ? "[]" : @root.to_s
  end

  # Indicates that parent is root in to_s
  def data; '*'; end

  protected

  def replace_child(from, to)
    if @root.eql? from
      @root = to
    else
      raise(ArgumentError,
            "#{from} is not a branch of #{self}")
    end
  end

end
