class ListNode
  attr_accessor :prev,:nxt,:val
  
  def initialize(prev=nil,nxt=nil,val="")
    @prev,@nxt,@val = prev,nxt,val
  end
  
  def to_a
    first = self
    first = first.prev while first.prev
    
    arr = []
    node = first
    while node.nxt
      arr << node
      node = node.nxt
    end
    arr << node
    arr
  end
end


###Partitions string into a linked list of lines
###For all lines, the last character is guaranteed to be a newline
###That includes the last, for simplicity's sake
###
###The cursor is between characters rather than on a character. Thus, inserting after
###is the same as inserting before
class LinkedListBuffer
  def initialize(str="")
    str << "\n" unless str[-1,1] == "\n"
    list = str.scan(/[^\n]*?\n/).map{|s| ListNode.new(nil,nil,s)}
    list.each_with_index do |node, idx|
      node.prev = list[idx-1] unless idx == 0
      node.nxt = list[idx+1]
    end
    @cur_line = list.first
    @line_idx = 0
  end
  
  def at_end?
    !@cur_line.nxt and @line_idx == @cur_line.val.length-1
  end
  
  def at_begin?
    !@cur_line.prev and @line_idx == 0
  end
  
  ##The construct ""<<ch is used so that ch may be either a string or an integer
  
  def insert(ch)
    unless "\n" == "" << ch
      @cur_line.val[@line_idx,1] = ""<<ch<<@cur_line.val[@line_idx]
    else
      @cur_line.val[@line_idx,1] = ""<<ch<<@cur_line.val[@line_idx]
      line = ListNode.new(@cur_line,@cur_line.nxt,@cur_line.val.slice!((@line_idx+1)..-1))
      @cur_line.nxt.prev = line if @cur_line.nxt
      @cur_line.nxt = line
    end
  end
  
  def del_after
    unless @cur_line.val[@line_idx] == ?\n or at_end?
      @cur_line.val.slice!(@line_idx,1)
    else
      if at_end?
        nil
      else
        @cur_line.val[-1,1] = @cur_line.nxt.val
        @cur_line.nxt = @cur_line.nxt.nxt
        "\n"
      end
    end
  end
  
  def del_before
    unless at_begin?
      cursor_left
      del_after
    else
      nil
    end
  end
  
  def cursor_left
    if at_begin?
      nil
    elsif @line_idx == 0
      @cur_line = @cur_line.prev
      @line_idx = @cur_line.val.length-1
      "\n"
    else
      @line_idx -= 1
      @cur_line.val[@line_idx,1]
    end
  end
  
  def cursor_right
    if at_end?
      nil
    elsif @line_idx + 1 == @cur_line.val.length
      @line_idx = 0
      @cur_line = @cur_line.nxt
      "\n"
    else
      @line_idx += 1
      @cur_line.val[@line_idx-1,1]
    end
  end

  def cursor_up
    if @cur_line.prev
      @cur_line = @cur_line.prev
      @line_idx = [@line_idx,@cur_line.val.length-1].min
    else
      nil
    end
  end

  def cursor_down
    if @cur_line.nxt
      @cur_line = @cur_line.nxt
      @line_idx = [@line_idx,@cur_line.val.length-1].min
    else
      nil
    end
  end
  
  def to_s
    @cur_line.val = @cur_line.val[0...@line_idx]+"|"+@cur_line.val[@line_idx..-1]
    str = @cur_line.to_a.map{|node| node.val}.join
    @cur_line.val.slice!(@line_idx)
    str
  end
  alias inspect to_s
end