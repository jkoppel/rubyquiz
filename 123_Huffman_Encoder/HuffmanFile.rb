 class HuffmanTreeNode
   attr_accessor :value, :weight, :left, :right

   def initialize(value, weight, left=nil, right=nil)
     @value = value
     @weight = weight
     @left = left
     @right = right
   end

   def char_code(c)
     return "" if leaf?
     if @right.value.include? c
       "1" + @right.char_code(c)
     else
       "0" + @left.char_code(c)
     end
   end

   #For Huffman tree algorithm
   def +(oth)
     HuffmanTreeNode.new(value + oth.value, weight + oth.weight,  
 self, oth)
   end

   def leaf?
     !(left || right)
   end

   def padding_character
     return @value if leaf?
     @right.padding_character
   end
 end

 #Algorithm for creating a Huffman tree:
 #Take the two nodes with the smallest weights (frequencies)
 #Replace them with a node containing said nodes as children and with
 #weight equal to the sum of their weights (purpose of + method)
 #Repeat untril 1 node is remaining. That is the root of your  
 Huffman tree
 def create_huffman_tree(nodes)
   return nodes.first if 1 == nodes.length

   nodeArr = nodes.sort_by{|n| n.weight}
   create_huffman_tree(nodeArr[2..-1] << (nodeArr[0] + nodeArr[1]))
 end

 def encode(str)

   tree = create_huffman_tree(
    str.split(//).zip(str.split(//).map{|c|
     str.count(c)}).uniq.map{|x| HuffmanTreeNode.new(*x)})

   #Serialization
   File.open($serialized_tree_file, "w") do |f|
     Marshal.dump(tree, f)
   end

   str += tree.padding_character

   str.split(//).map {|c| tree.char_code(c)}.join
 end

 def decode(encoded)
   tree = nil
   File.open($serialized_tree_file) do |f|
     tree = Marshal.load(f)
   end

   decoded = ""

   #Removing any formatting
   encoded.gsub!(/[^01]/,"")

   #Removing padding character
   encoded.sub!(/#{tree.char_code(tree.padding_character)}0*?$/,"")

   node = tree

   encoded.each_char do |c|
     if c == "0"
       node = node.left
     else
       node = node.right
     end


     if node.leaf?
      decoded += node.value
      node = tree
     end
   end

   decoded
 end

 def format_encoded(encoded, original)
   while encoded.length % 8 != 0
     encoded += "0"
   end
   puts "Encoded: "

   ebytes = encoded.length / 8.0

   encoded.gsub!(/([01]{8})/, '\1 ')
   encoded.gsub!(/(([01]{8} ){5})/, '\1\n').gsub!("\\n","\n")
   puts encoded

   puts "Encoded bytes:" , ebytes.to_i
   puts "\nOriginal: ",original
   puts "Original bytes: ", (obytes = original.length)

   puts "Compressed: " + ((obytes - ebytes)/obytes * 100).round.to_s  
 + "%"
 end

 #Using optparse to get a -d/-e was too messy. Too much work for  what it is.
 puts "Encode(e) or decode(d)"
 if gets.chomp == "e"
   puts "Enter text to encode"
   format_encoded(encode(gets.chomp), $_.chomp)
 elsif $_.chomp == "d"
   puts "Enter bytes to decode"
   puts decode(gets.chomp)
 end
