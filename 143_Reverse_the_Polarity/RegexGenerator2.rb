INF_QUANTIFIER_LEN = 5
$capturing_groups = []

module Invokable
  def curry(*largs)
    proc {|*args| self.call(*(largs+args))}
  end
end
class Method
  include Invokable
end

$escape_seqs = {
  ?a => ?\a,
  ?b => ?\b,
  ?f => ?\f,
  ?n => ?\n,
  ?r => ?\r,
  ?t => ?\t,
  ?v => ?\v
}

$predefined_classes = {
  ?d => (?0..?9).to_a,
  ?D => (0..255).to_a - (?0..?9).to_a,
  ?s => [" "[0], ?\t,?\n,?\v,?\r],
  ?S => (0..255).to_a - [" "[0], ?\t,?\n,?\v,?\r],
  ?w => (?a..?z).to_a + (?A..?Z).to_a + (?0..?9).to_a + [?_],
  ?W => (0..255).to_a - 
       ((?a..?z).to_a + (?A..?Z).to_a + (?0..?9).to_a + [?_])
}

###Given a StringIO removes the next character if it's a ?
def remove_reluctant(strio)
  return if strio.eof?
  if (ch=strio.getc) == ??
    #Do nothing
  else
    strio.ungetc(ch)
  end
end

###Given a StringIO, returns the everything until an unnested closed parenthesis is read
def get_outer_layer(strio)
  str = ""
  nest = 0
  until (ch=strio.read(1)) == ')' and nest == 0
    str << ch
    str << strio.read(1) if ch == "\\"
    nest += 1 if ch == '('
    nest -= 1 if ch == ')'
  end
  str
end

###Returns an array whose elements are subarrays containing all distinct
###combinations of one element from each argument
def all_combinations(first, *rest)
  return first if rest == []
  rest = all_combinations(*rest)
  combs = []
  first.each do |v1|
    rest.each do |v2|
      combs << v1 + v2
    end
  end
  combs
end

###The Generator class helps implement a Ruby version of a Python-style generator
###A generator is like an iterator, except that it returns a value instead
###of yielding a value
###
###All generators must support next! and reset methods
###This class, in addition to being a superclass of other generators, also implements
###a default "cached" generator.
class Generator
  def deep_dup
    oth = self.dup
    instance_variables.each do |var|
      if instance_variable_get(var).is_a? Generator
        other.instance_variable_set(var, instance_variable_get(var).deep_dup)
      end
    end
    oth
  end
  
  def Generator.generator_vars(var_hsh)
    class_eval <<-EOC
      def reset
        #{var_hsh.inspect}.each do |k,v|
          instance_variable_set(k,v)
        end
      end
    EOC
  end
  
  attr_reader :cur
  generator_vars :@idx => -1, :@cur => nil #default reset
  #@@template = [:@cache] #default is to iterate through a cache
  
  def initialize(*args)
    (self.class.send(:class_variable_get, :@@template) rescue [:@cache]).
        each_with_index do |name, idx|
         instance_variable_set(name, args[idx])
       end
    reset
  end
  
  #Default next! is to retrieve from a cache
  def next!
    @cur = @cache[@idx+=1]
  end
end

###Following are generators used to iterate through all the possible matches.
###The following methods not within subclasses of generator are simply meant to
###be used as a cache

class CapturingGroupGenerator < Generator
  @@template = [:@subgens]
  def reset
    @cur = nil
    @subgens.each {|gen| gen.reset}
  end
  
  def next!
    str = ""
    @subgens.first.next!
    @subgens.each_with_index do |gen, idx|
      if gen.cur == nil
        gen.reset
        @subgens[idx+1].next! rescue return @cur=nil #gone through everything
        if gen.next! == nil #Resetting didn't help
          return nil
        end
      end
      str << gen.cur
    end
    @cur = str
  end
end
      

class OrGenerator < Generator
  generator_vars :@cur => nil, :@left_nil => false
  @@template = [:@left, :@right]
  
  def next!
    @cur = unless @left_nil
                if @left.next!
                  @left.cur
                else
                  @right.next!
                end
              else
                @right.next!
              end
  end
end

class QuantifiedRangeGenerator < Generator
  @@template = [:@range, :@subgen]
  def reset
    @cur = nil
    @len = @range.begin - 1
    @cur_len_gen = nil
  end
  
  def next!
    if @cur_len_gen == nil
      @len += 1
      return nil if @len > @range.end
      @cur_len_gen = CapturingGroupGenerator.new(
                ([0]*@len).map{@subgen.deep_dup})
    end
    @cur = @cur_len_gen.next!
  end
end

class BackReferenceGenerator < Generator
  @@template = [:@num]
  def reset
    @cache = [$capturing_groups[@num].cur]
    @idx = -1
    @cur = nil
  end
  #Just uses the default next!
end

def char_class(ascii_vals)
  ascii_vals.map{|i|i.chr}
end

###Following is a hash that maps characters to procedures accepting the
###previously-encountered entities and the StringIO of the regex-source reader.
###These procedures add to prev curried functions that a form a tree of functions
###that return all possible values
$macro_chars = {
  ?\\ => proc do |prev, strio|
              ch = strio.getc
              prev << if $predefined_classes.has_key? ch
                            Generator.new(char_class($predefined_classes[ch]))
                          elsif $escape_seqs.has_key? ch
                            Generator.new([$escape_seqs[ch]])
                          elsif ?0..?9 === ch
                            num_str = ch.chr
                            num_str << ch until strio.eof? or
                                  (ch=strio.getc) !~ /\d/
                            strio.ungetc(ch) unless strio.eof
                            BackReferenceGenerator.new(num_str.to_i)
                          else
                            Generator.new([ch.chr])
                          end
            end,
  ?. => proc do |prev, strio|
            prev <<  Generator.new(char_class((0..255).to_a))
          end,
  ?[ => proc do |prev,strio|
            ascii_vals = []
            
            char_str = strio.gets("]")[0...-1]
            
            neg = if char_str[0] == ?^
                      char_str = char_str[1..-1]
                      true
                    else
                      false
                    end
              
            ##The next three lines handle escape characters. \- is a special case
            char_str.gsub!(/\\-/) {ascii_vals << ?-; ""}
            char_str.gsub!(/\\(.)/) {
              $escape_seqs.has_key?($1[0]) ? $escape_seqs[$1[0]] : $1}
            char_str.scan(/.-.|./) do |seg|
              if seg =~ /(.)-(.)/
                ascii_vals += (($1[0])..($2[0])).to_a
              else
                ascii_vals << seg[0]
              end
            end
            prev << Generator.new(char_class(
              neg ? (0..255).to_a - ascii_vals : ascii_vals))
          end,
  ?( => proc do |prev,strio|
            n = $capturing_groups.length
            $capturing_groups[n] = parse_regex(get_outer_layer(strio))
           end,
  ?* => proc do |prev, strio|
              remove_reluctant(strio)
              prev[-1] =QuantifiedRangeGenerator.new(
                  0..INF_QUANTIFIER_LEN, prev[-1])
            end,
  ?+ => proc do |prev, strio|
              remove_reluctant(strio)
              prev[-1] =QuantifiedRangeGenerator.new(
                  1..INF_QUANTIFIER_LEN, prev[-1])
           end,
    ?? => proc do |prev, strio|
              remove_reluctant(strio)
              prev[-1] =QuantifiedRangeGenerator.new(0..1, prev[-1])
             end,
    ?{ => proc do |prev, strio|
              remove_reluctant(strio)
              contents = strio.gets("}")
              prev[-1] =  if contents =~ /(\d+),(\d+)/
                                 QuantifiedRangeGenerator.new(
                                    ($1.to_i)..($2.to_i), prev[-1])
                              elsif contents=~ /(\d+),/
                                 QuantifiedRangeGenerator.new(
                                    ($1.to_i)..INF_QUANTIFIER_LEN, prev[-1])
                               elsif contents =~ /(\d+)/
                                 QuantifiedRangeGenerator.new(
                                    ($1.to_i)..($1.to_i), prev[-1])
                               end
              end,
    ?| => proc do |prev, strio|
              prev[0..-1] = OrGenerator.new(
                    CapturingGroupGenerator.new(prev[0..-1]),
                    parse_regex(strio.gets(nil)))
                  end
}

def parse_regex(src)
  return Generator.new([""]) if src == "" or src.nil?
  gen_arr = []
  strio = StringIO.new(src)
  until strio.eof?
    ch = strio.getc
    if $macro_chars.has_key? ch
      $macro_chars[ch].call(gen_arr, strio)
    else
      gen_arr << Generator.new([ch.chr])
    end
  end
  CapturingGroupGenerator.new(gen_arr)
end

class Regexp
  def generate
    $capturing_groups = [nil]
    topgen = parse_regex(self.source)
    $capturing_groups[0] = topgen
    #matches = []
    #matches << topgen.cur until topgen.next!.nil?
  end
end