DX = 1e-4
EPSILON = 1e-7

def nderiv(f)
  lambda {|x| (f[x+DX]-f[x-DX])/(2*DX)}
end

MAX_ITERATIONS = 500
def find_zero(f, start)
  iterations = 0
  f_prime = nderiv(f)
  x = start
  until f[x].abs < EPSILON or (iterations+=1) > MAX_ITERATIONS
    x = x - f[x]/f_prime[x]
  end
  if iterations > MAX_ITERATIONS
    nil
  else
    x
  end
end

def irr(cash_flows)
  net_value = lambda do |irr|
    (0...cash_flows.length).to_a.inject(0) do |s,t|
      s+cash_flows[t]/((1+irr)**t)
    end
  end
  
  find_zero(net_value,0.1) or find_zero(net_value,-0.1)
end