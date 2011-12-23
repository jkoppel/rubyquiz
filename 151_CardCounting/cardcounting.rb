####Usage: ruby cardcounting.rb <time in s> <num cards to display at once> <num decks>


COUNT_QUERY_CHANCE = 0.2


CARDS = %w[Deuce Three Four Five Six Seven Eight Nine Ten
                  Jack Queen King Ace]
SUITS = %w[Hearts Clubs Spades Diamonds]

def cartesian_product(first, *rest)
  return first if rest == []
  rest = cartesian_product(*rest)
  combs = block_given? ? nil : []
  first.each do |v1|
    rest.each do |v2|
      if block_given?
        yield v1+v2
      else
        combs << (v1 + v2)
      end
    end
  end
  combs
end

class Array
  def sum
    self.inject(0){|s,n|s+n}
  end
end

###Knock-out systen
count_cards = proc do |decks, seen|
 vals = {"Deuce"=>1,"Three"=>1,"Four"=>1,"Five"=>1,"Six"=>1,            "Seven"=>1,"Eight"=>0,"Nine"=>0,"Ten"=>-1,"Jack"=>-1,            "Queen"=>-1,"King"=>-1,"Ace"=>-1}
  init_val = 4-4*decks
  init_val + seen.map{|s|vals[s.split.first]}.sum
end

###Hi-lo systen
#~ count_cards = proc do |decks, seen|
 #~ vals = {"Deuce"=>1,"Three"=>1,"Four"=>1,"Five"=>1,"Six"=>1,
            #~ "Seven"=>1,"Eight"=>1,"Nine"=>0,"Ten"=>-1,"Jack"=>-1,
            #~ "Queen"=>-1,"King"=>-1,"Ace"=>-1}
  #~ init_val = 0
  #~ init_val + seen.map{|s|vals[s.split.first]}.sum
#~ end

time, simul_display, decks = ARGV.map{|el|el.to_f}

deck = ([nil]*decks).map{cartesian_product(CARDS.map{|el|[el]},SUITS.map{|el|[el]}).
            map{|(c,s)|"#{c} of #{s}"}}.flatten.sort_by{rand}

seen = []
delay = time/(deck.length.to_f/simul_display)

(deck.length.to_f/simul_display).ceil.times do
  puts "\n"*100
  puts deck[0...simul_display]
  seen += deck.slice!(0...simul_display)
  sleep delay
  if rand < COUNT_QUERY_CHANCE
    print "Current count=?"
    response = $stdin.gets.to_i
    if response == (cnt=count_cards.call(decks,seen))
      puts "Correct"
    else
      puts "Incorrect: Correct is #{cnt}"
    end
    sleep delay/2
  end
end