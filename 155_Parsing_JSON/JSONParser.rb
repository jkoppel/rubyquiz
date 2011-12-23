class StringIO
  def strip!
    ch = read(1)
    ch = read(1) while /\s/ =~ ch
    ungetc ch[0]
    self
  end
  
  def sees?(str1)
    str2 = read(str1.length)
    str2.reverse.scan(/./) {|ch| ungetc ch[0]}
    str2 == str1
  end
  
  alias oldread read
  def read(expr,*buffer)
    return oldread(expr,*buffer) unless expr.is_a? Regexp
    str = ""
    str << getc until eof? or (expr =~ str) == 0
    if eof? and (expr =~ str) != 0
      str.reverse.scan(/./){|ch| ungetc ch[0]}
      return nil
    end
    maxmtch = str
    until eof?
      str << getc until eof? or expr.match(str)[0] != str
      str << getc until eof? or expr.match(str)[0] == str
      maxmtch = expr.match(str)[0]
    end
    str[maxmtch.length..-1].reverse.scan(/./){|ch|ungetc ch[0]}
    str = maxmtch
    if expr.match(str)[0]==str
      str
    else
      ungetc str[-1]
      str[0...-1]
    end
  end
end

class JSONParser
  
  def parse(str)
    parse_next(StringIO.new(str))
  end
  
  private
  
  def parse_next(strio)
    strio.strip!
    if el=number(strio)
      return el
    elsif el=string(strio)
      return el
    end
    {"true"=>true,"false"=>false,"null"=>nil}.each_pair do |k,v|
      if strio.sees? k
        strio.read k.length
        return v
      end
    end
    
    if strio.sees?("{")
      obj = Hash.new
      strio.getc
      
      until strio.strip!.sees?("}")
        key = string(strio) or raise
        strio.strip!
        raise unless strio.read(1) == ':'
        val = parse_next(strio)
        obj[key] = val
        strio.strip!
        raise unless strio.sees?('}') or strio.read(1) == ','
      end
      strio.getc
      obj
    elsif strio.read(1) == '['
      arr = Array.new
      until strio.strip!.sees?("]")
        arr << parse_next(strio)
        raise unless strio.sees?("]") or strio.read(1) == ','
      end
      strio.getc
      arr
    else
      raise
    end        
  end
  
  def string(strio)
    str=strio.read(/\"([^\"\\]|\\\"|\\\\|\\\/|\\b|\\f|\\n|\\r|\\t|\\u[a-fA-F0-9]{4})*\"/).
          to_s.gsub(/\\u([a-fA-F0-9]{4})/){$1.to_i(16).chr}[1...-1] \
                      or return nil
    str.gsub!(/\\[\"\\\/bfnrt]/){|s|eval("\"#{s}\"")}
    str
  end
  
  def number(strio)
    eval (strio.read(/-?(0|[1-9]\d*)(\.\d*)?([eE][+-]?\d+)?/).to_s)
  end
end

require "test/unit"

class TestJSONParser < Test::Unit::TestCase
def setup
@parser = JSONParser.new
end

def test_keyword_parsing
assert_equal(true, @parser.parse("true"))
assert_equal(false, @parser.parse("false"))
assert_equal(nil, @parser.parse("null"))
end

def test_number_parsing
assert_equal(42, @parser.parse("42"))
assert_equal(-13, @parser.parse("-13"))
assert_equal(3.1415, @parser.parse("3.1415"))
assert_equal(-0.01, @parser.parse("-0.01"))

assert_equal(0.2e1, @parser.parse("0.2e1"))
assert_equal(0.2e+1, @parser.parse("0.2e+1"))
assert_equal(0.2e-1, @parser.parse("0.2e-1"))
assert_equal(0.2E1, @parser.parse("0.2e1"))
end

def test_string_parsing
assert_equal(String.new, @parser.parse(%Q{""}))
assert_equal("JSON", @parser.parse(%Q{"JSON"}))

assert_equal( %Q{nested "quotes"},
@parser.parse('"nested \"quotes\""') )
assert_equal("\n", @parser.parse(%Q{"\\n"}))
assert_equal( "a",
@parser.parse(%Q{"\\u#{"%04X" % ?a}"}) )
end

def test_array_parsing
assert_equal(Array.new, @parser.parse(%Q{[]}))
assert_equal( ["JSON", 3.1415, true],
@parser.parse(%Q{["JSON", 3.1415, true]}) )
assert_equal([1, [2, [3]]], @parser.parse(%Q{[1, [2, [3]]]}))
end

def test_object_parsing
assert_equal(Hash.new, @parser.parse(%Q{{}}))
assert_equal( {"JSON" => 3.1415, "data" => true},
@parser.parse(%Q{{"JSON": 3.1415, "data": true}}) )
assert_equal( { "Array" => [1, 2, 3],
"Object" => {"nested" => "objects"} },
@parser.parse(<<-END_OBJECT) )
{"Array": [1, 2, 3], "Object": {"nested": "objects"}}
END_OBJECT
end

def test_parse_errors
assert_raise(RuntimeError) { @parser.parse("{") }
assert_raise(RuntimeError) { @parser.parse(%q{{"key": true false}}) }

assert_raise(RuntimeError) { @parser.parse("[") }
assert_raise(RuntimeError) { @parser.parse("[1,,2]") }

assert_raise(RuntimeError) { @parser.parse(%Q{"}) }
assert_raise(RuntimeError) { @parser.parse(%Q{"\\i"}) }

assert_raise(RuntimeError) { @parser.parse("$1,000") }
assert_raise(RuntimeError) { @parser.parse("1_000") }
assert_raise(RuntimeError) { @parser.parse("1K") }

assert_raise(RuntimeError) { @parser.parse("unknown") }
end
end