CARDS = (2..10).inject({}){|h,n|h[n]=n;h}.merge(
  {:J=>10,
    :Q=>10,
    :K=>10,
    :A=>nil})

MAX_HAND = 21
HIT_THRESHOLD = 17
NUM_DECKS = 2
HIGH_ACE = 11
LOW_ACE = 1
CARD_REPS = 4

class Array
  def count(obj)
    select{|el|el==obj}.size
  end
  
  def sum
    inject(0){|s,n|s+n}
  end
end

def sum_hand(hand)
  sum = hand.map{|c|CARDS[c]}.compact.sum
  sum += hand.count(:A)*HIGH_ACE
  hand.count(:A).times{sum -= (HIGH_ACE-LOW_ACE) if sum > MAX_HAND}
  sum <= MAX_HAND ? sum : nil
end

def expand_prob_hash(prob_hash)
  return if 0 == prob_hash[:prob] or nil == sum_hand(prob_hash[:hand]) or
      HIT_THRESHOLD<=sum_hand(prob_hash[:hand])
  CARDS.keys.each do |c|
    mod_deck = prob_hash[:deck].clone
    mod_deck[c] -= 1
    prob_hash[c] = {:hand=>prob_hash[:hand]+[c],
                              :deck=>mod_deck,
                              :prob=>prob_hash[:prob]*
                                  prob_hash[:deck][c]/prob_hash[:deck].values.sum}
    expand_prob_hash(prob_hash[c])
  end
end

def sum_probs(prob_hash)
  probs=((HIT_THRESHOLD..MAX_HAND).to_a+[nil]).inject({}){|h,n|h[n]=0.0;h}
  if prob_hash.has_key? :A
    CARDS.keys.each do |c|
      prob_part = sum_probs(prob_hash[c])
      prob_part.each_pair {|k,v| probs[k] += v}
    end
  elsif 0 == prob_hash[:prob]
    #do nothing
  else
      probs[sum_hand(prob_hash[:hand])] += prob_hash[:prob]
  end
  probs
end

$probs = {:hand=>[],
            :deck=>CARDS.keys.inject({}){|h,c|h[c]=CARD_REPS*NUM_DECKS;h},
            :prob=>1.0}
expand_prob_hash($probs)

puts "  "+((HIT_THRESHOLD..MAX_HAND).to_a+["BUST"]).map{|el|
  "%8s"%[el]}.join
[2,3,4,5,6,7,8,9,10,:J,:Q,:K,:A].each do |c|
  p = sum_probs($probs[c])
  printf "%2s ",c
  ((HIT_THRESHOLD..MAX_HAND).to_a+[nil]).each{|n|printf "%6.2f%% ",p[n]*100*CARDS.size}
  puts
end