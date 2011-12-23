require 'test/unit'

$days = {"Sun"=>0,
              "Mon"=>1,
              "Tue"=>2,
              "Wed"=>3,
              "Thu"=>4,
              "Fri"=>5,
              "Sat"=>6}

class Array
  def some
    each {|el| return true if yield el}
    false
  end
end

class TimeWindow
  def initialize(win_str)
    @times = ([nil]*7).map{[]}
    win_str << " " #In case of empty
    win_str.split(/;/).each do |win|
      days_str = win.match(/(((#{$days.keys.join('|')}|)( |-)?)*)/)[0].strip
      days = []
      days_str.scan(/#{$days.keys.join('|')}/) do |day|
        days << $days[day]
      end
      days_str.scan(/(#{$days.keys.join('|')})-(#{$days.keys.join('|')})/) do
        a = $days[$1]
        b = $days[$2]
        days += (a..(b > a ? b : b+7)).to_a.map{|d|d%7}
      end
      days = (0..6).to_a if days.empty?
      
      times = []
      win.scan(/(\d{4})-(\d{4})/) do
        times << (($1.to_i)...($2.to_i))
      end
      times = [0..2400] if times.empty?
      
      days.each do |d|
        times.each do |t|
          @times[d] << t
        end
      end
    end
    
    def include?(time)
      @times[time.wday].some{|trange| trange === (time.hour*100+time.min)}
    end
  end
end

class TestTimeWindow < Test::Unit::TestCase
def test_window_1
w = TimeWindow.new("Sat-Sun; Mon Wed 0700-0900; Thu 0700-0900 1000-1200")

assert ! w.include?(Time.mktime(2007,9,25,8,0,0)) # Tue
assert w.include?(Time.mktime(2007,9,26,8,0,0)) # Wed
assert ! w.include?(Time.mktime(2007,9,26,11,0,0))
assert ! w.include?(Time.mktime(2007,9,27,6,59,59)) # Thu
assert w.include?(Time.mktime(2007,9,27,7,0,0))
assert w.include?(Time.mktime(2007,9,27,8,59,59))
assert ! w.include?(Time.mktime(2007,9,27,9,0,0))
assert w.include?(Time.mktime(2007,9,27,11,0,0))
assert w.include?(Time.mktime(2007,9,29,11,0,0)) # Sat
assert w.include?(Time.mktime(2007,9,29,0,0,0))
assert w.include?(Time.mktime(2007,9,29,23,59,59))
end

def test_window_2
w = TimeWindow.new("Fri-Mon")
assert ! w.include?(Time.mktime(2007,9,27)) # Thu
assert w.include?(Time.mktime(2007,9,28))
assert w.include?(Time.mktime(2007,9,29))
assert w.include?(Time.mktime(2007,9,30))
assert w.include?(Time.mktime(2007,10,1))
assert ! w.include?(Time.mktime(2007,10,2)) # Tue
end

def test_window_nil
w = TimeWindow.new("")
assert w.include?(Time.mktime(2007,9,25,1,2,3)) # all times
end
end