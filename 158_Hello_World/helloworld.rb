module Kernel
  def meth(&block)
    o=Object.new
    o.instance_variable_set(:@block,block)
    def o.__call(&b)
      @block2=b
      instance_eval &@block
    end
    def o.yiel
      @block2.call
    end
    o.method(:__call)
  end
end

meth do
  yiel
  puts "!"
end.call &(meth do
  proc do
    yiel
    print "d"
  end
end.call &(meth do
  proc do
    yiel
    print "l"
  end
end.call(&meth do
  proc do
    yiel
    print "r"
  end
end.call(&meth do
  proc do
    yiel
    print "o"
  end
end.call(&meth do
  proc do
    yiel
    print "w"
  end
end.call(&meth do
  proc do
    yiel
    print " "
  end
end.call(&meth do
  proc do
    yiel
    print ","
  end
end.call(&meth do
  proc do
    yiel
    print "o"
  end
end.call(&meth do
  proc do
    yiel
    print "l"
  end
end.call(&meth do
  proc do
    yiel
    print "l"
  end
end.call(&meth do
  proc do
    yiel
    print "e"
  end
end.call(&meth do
  print "H"
end))))))))))))