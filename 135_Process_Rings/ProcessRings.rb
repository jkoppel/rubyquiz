$processes = []

def kill_processes
  $processes.each do |thr|
    thr.exit!
  end
end

thread_proc = proc do
  Thread.stop
  if Thread.current[:count] == 0
    Thread.current[:next] = $processes.first
  else
    Thread.current[:next] = Thread.new(&thread_proc)
    Thread.current[:next][:count] = Thread.current[:count] - 1
    $processes.push(Thread.current[:next])
    true until Thread.current[:next].stop?
    Thread.current[:next].run
  end
  while true
    Thread.stop
    msg = Thread.current[:message]
    cnt = Thread.current[:message_count]

    Thread.current[:message] = nil
    Thread.current[:message_count] = nil
    
    if cnt == 0
      kill_processes
    else
      Thread.current[:next][:message_count] = cnt - 1
      Thread.current[:next][:message] = msg
      #On small rings, the message can circle around before the first thread has stopped
      true until Thread.current[:next].stop?
      Thread.current[:next].run
    end
  end
end

processes, cycles = ARGV.map{|n| n.chomp.to_i}

$processes.push(Thread.new(&thread_proc))
true until $processes.first.stop?
$processes.first[:count] = processes - 1
$processes.first.run

puts "Creating #{processes} processes..."
sleep(0.1) until $processes.length == processes

puts "Timer started."
start_time = Time.new

puts "Sending a message around the ring #{cycles} times..."
$processes.first[:message_count] = processes * cycles
$processes.first[:message] = "Good day!"
$processes.first.run

sleep(0.1) while $processes.first.alive?

puts "Done."
puts "Time in seconds: " + (Time.new.to_i - start_time.to_i).to_s