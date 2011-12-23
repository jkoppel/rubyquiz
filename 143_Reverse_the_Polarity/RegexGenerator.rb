INF_QUANTIFIER_LEN = 5

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

###The following methods return an array of all valid matches to the entity
###
###Note: The functions corresponding to regex operators that operate on 
###valid subregexes accept curried functions that return the values to operate on,
###not the values themselves. (That's why the quote function exists.)

def char_class(ascii_vals)
  ascii_vals.map{|i|i.chr}
end

def or(left, right)
  left.call+right.call
end

def quantified_range(range, vals)
  vals = [vals.call] * range.end
  range.to_a.map{|n|n == 0 ? "" : all_combinations(*vals[0..(n-1)])}.flatten
end

def capturing_group(vals)
  all_combinations(*vals.map{|f|f.call})
end

def quote(val)
  [val]
end

###Following is a hash that maps characters to procedures accepting the
###previously-encountered entities and the StringIO of the regex-source reader.
###These procedures add to prev curried functions that a form a tree of functions
###that return all possible values
$macro_chars = {
  ?\\ => proc do |prev, strio|
              ch = strio.getc
              prev << if $predefined_classes.has_key? ch
                            method(:char_class).curry($predefined_classes[ch])
                          elsif $escape_seqs.has_key? ch
                            method(:quote).curry($escape_seqs[ch])
                          else
                            method(:quote).curry(ch.chr)
                          end
            end,
  ?. => proc do |prev, strio|
            prev << method(:char_class).curry((0..255).to_a)
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
            prev << method(:char_class).curry(
              neg ? (0..255).to_a - ascii_vals : ascii_vals)
          end,
  ?( => proc do |prev,strio|
            prev << parse_regex(get_outer_layer(strio))
           end,
  ?* => proc do |prev, strio|
              remove_reluctant(strio)
              prev[-1] = method(:quantified_range).
                  curry(0..INF_QUANTIFIER_LEN, prev[-1])
            end,
  ?+ => proc do |prev, strio|
              remove_reluctant(strio)
              prev[-1] = method(:quantified_range).
                  curry(1..INF_QUANTIFIER_LEN, prev[-1])
           end,
    ?? => proc do |prev, strio|
              remove_reluctant(strio)
              prev[-1] = method(:quantified_range).
                  curry(0..1, prev[-1])
             end,
    ?{ => proc do |prev, strio|
              remove_reluctant(strio)
              contents = strio.gets("}")
              prev[-1] =  if contents =~ /(\d+),(\d+)/
                                 method(:quantified_range).curry(($1.to_i)..($2.to_i), prev[-1])
                              elsif contents=~ /(\d+),/
                                 method(:quantified_range).curry(
                                   ($1.to_i)..INF_QUANTIFIER_LEN, prev[-1])
                               elsif contents =~ /(\d+)/
                                 method(:quantified_range).curry(($1.to_i)..($1.to_i), prev[-1])
                               end
              end,
    ?| => proc do |prev, strio|
              prev[0..-1] = method(:or).curry(
                    method(:capturing_group).curry(prev[0..-1]),
                    parse_regex(strio.gets(nil)))
                  end
}

def parse_regex(src)
  return method(:quote).curry("") if src == "" or src.nil?
  func_arr = []
  strio = StringIO.new(src)
  until strio.eof?
    ch = strio.getc
    if $macro_chars.has_key? ch
      $macro_chars[ch].call(func_arr, strio)
    else
      func_arr << method(:quote).curry(ch.chr)
    end
  end
  method(:capturing_group).curry(func_arr)
end

class Regexp
  def generate
    parse_regex(self.source).call
  end
end