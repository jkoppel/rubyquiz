$x = 0
$y = 0

def print_rope(tree)
  arr = ([nil]*tree.height).map{[nil] * tree.width}
  $y = arr.length / 2
  $x = arr[0].length / 2
  trav(tree) do |node|
    if Rope == node
      arr[$y][$x] = "/ \\"
    else
      arr[$y][$x] = node.to_s.inspect
    end
  end
  arr.each do |row|
    row.each do |cell|
      if cell = nil
        puts "   "
      else
        puts cell
      end
    end
  end
end
  

def trav(tree, &block)
  unless Rope === tree
    block.call(tree)
    return
  end
  $x -=1
  $y +=1
  trav(tree.left,&block)
  $x +=1
  $y -=1
  block.call(tree)
  $x +=1
  $y +=1
  trav(tree.right, &block)
  $x -=1
  $y -=1
end