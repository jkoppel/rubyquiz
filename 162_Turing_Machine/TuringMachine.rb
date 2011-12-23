state = nil
instructions =  File.open(ARGV[0]) do |f|
                      f.readlines.map{|s|
                        (s=s.match(/^[^#]+/)[0].strip).empty? ? nil : s}.compact.
                      inject({}){|hsh,s|
                        md=s.match(/(\w+)\s+(\w)\s+(\w+)\s+(\w)\s+([LR])/)
                        state = state || md[1]
                        hsh[[md[1],md[2]]]=[md[3],md[4],md[5]]
                        hsh
                      }
                    end

tape = Hash.new do |cell,v|
  h = cell.dup
  h[:C] = '_'
  h[v=='L' ? 'R' : 'L'] = cell
  cell[v] = h
end

tape[:C] = '_'
ARGV[1].to_s.split(//).reverse.each{|c|tape=tape['L'];tape[:C]=c}

until instructions[[state,tape[:C]]].nil?
  state, ch, move = instructions[[state,tape[:C]]]
  tape[:C] = ch
  tape = tape[move]
end

tape = tape['L'] while tape.keys.include? 'L'
output = [tape[:C]]
(tape = tape['R']; output << tape[:C]) while tape.keys.include? 'R'

puts output.reject{|c|c=='_'}.join
