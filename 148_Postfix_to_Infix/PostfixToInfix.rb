PREC = {:+ => 0,:- => 0,:* => 1,:/ => 1,:% => 1,:^ => 2}
LEFT_ASSOCS = {:+ => true,:- => true,:* => true,:/ => true,
          :% => true,:^ => false}
RIGHT_ASSOCS = {:+ => true,:- => false,:* => true,:/ => false,
          :% => false,:^ => true}

class TreeNode
  attr_accessor :el,:left,:right
  def initialize(el,left,right)
    @el,@left,@right=el,left,right
  end
  
  def TreeNode.from_postfix(exp_arr)
    stack = []
    exp_arr.each do |exp_str|
      if PREC.keys.include? exp_str.to_sym
        op2,op1 = stack.pop,stack.pop
        stack.push(TreeNode.new(exp_str.to_sym,op1,op2))
      else
        stack.push(exp_str.to_f)
      end
    end
    stack.first
  end
  
  def to_minparen_infix
    l,r = [left,right].map{|o|o.to_minparen_infix}
    l = "(#{l})" if left.respond_to?(:el) and (PREC[left.el]<PREC[self.el] or  
        (PREC[self.el]==PREC[left.el] and not LEFT_ASSOCS[self.el]))
    r= "(#{r})" if right.respond_to?(:el) and (PREC[right.el]<PREC[self.el] or 
        (PREC[self.el]==PREC[right.el] and not RIGHT_ASSOCS[self.el]))
    l+" #{self.el} "+r
  end
end

class Float
  def to_minparen_infix
    if self%1==0
      to_i.to_s
    else
      to_s
    end
  end
end

puts TreeNode.from_postfix(ARGV.first.split(/ /)).to_minparen_infix