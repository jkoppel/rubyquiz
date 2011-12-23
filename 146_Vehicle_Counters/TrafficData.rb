require 'enumerator'
require 'units/standard'
require 'math/statistics'

#Assumes the same set of tire's time between crossing tube A and tube B will be 5 ms
MAX_CROSS_TUBE_TRAVEL_TIME = 0.005.seconds

AVG_WHEELBASE = 100.inches

#For compatibility between units and statistics libraries
def unset_unit(n)
  n.instance_variable_set(:@unit,nil)
  n.instance_variable_set(:@kind,nil)
end

module Math
  module Statistics
    def median
      a = to_a.sort
      [a[(a/2.0).floor],a[(a/2.0).ceil]].avg
    end
    alias med median
  end
end

class Array
  include Math::Statistics
end

module Enumerable  
  def slices(n)
    slices = []
    each_slice(n){|s| slices << s}
    slices
  end
  
  def conses(n)
    conses = []
    each_cons(n){|s| conses << s}
    conses
  end
end

class TrafficData
  def initialize(info)
    parse_info(info)
  end
  
  def traffic_in_period(start,stop,dir=:north)
    instance_variable_get("@#{dir.to_s}bound_cars".to_sym).
      select{|car| start..stop === car.t1}.size
  end
  
  def speed_distr(start,stop,dir=:north)
     speeds=instance_variable_get(
      "@#{dir.to_s}bound_cars".to_sym).
      select{|car| start..stop === car.t1}.map{|car|car.speed}
      {:min=>speeds.Min,
        :max=> speeds.Max,
        :var => speeds.var,
        :std => speeds.std,
        :avg => speeds.avg,
        :med => speeds.med}
  end
      
  def avg_intercar_dist(start,stop,dir=:north)
    cars=instance_variable_get(
     "@#{dir.to_s}bound_cars".to_sym).
         select{|car| start..stop === car.t1}
    cars.conses(2).map do |(c1,c2)|
      dt = c1.t2 = c2.t1
      s = [c1.speed,c2.speed].avg
      (s*dt.to_hours).to_feet
    end.avg
  end    
  
  private
  
  def parse_info(info)
    tire_records = info.split(/\n/)
    
    southbound_tires = []
    northbound_tires = []
    
    days_elapsed = 0
    skip_next = false
    
    tire_records.each_cons(2) do |(a,b)|
      
      ta = (a[1..-1].to_i/1000.0).seconds
      tb = (b[1..-1].to_i/1000.0).seconds
      
      ta += days_elapsed.days.to_seconds
      if tb < ta
        days_elapsed += 1
      end
      tb += days_elapsed.days.to_seconds
      
      if skip_next
        skip_next = false
        next
      end
      
      if a[0]==?A and b[0]==?B and tb - ta < MAX_CROSS_TUBE_TRAVEL_TIME
        unset_unit(ta)
        unset_unit(tb)
        southbound_tires << [ta,tb].avg.seconds
        skip_next = true
      else
        northbound_tires << ta
      end
    end
    
    @southbound_cars = southbound_tires.slices(2).map{|(t1,t2)|
      VehicleData.new(t1,t2)}
    @northbound_cars = southbound_tires.slices(2).map{|(t1,t2)|
      VehicleData.new(t1,t2)}
  end
end

class VehicleData
  attr_reader :speed, :t1, :t2
  def initialize(t1,t2)
    @t1 = t1
    @t2 = t2
    @speed = AVG_WHEELBASE.to_miles / (@t2-@t1).to_hours
  end
end

class Hash
  def inspect
    str= ""
    each_pair do |k,v|
      str << "#{k}: #{v}"
    end
    str
  end
end

def time_str(t)
  time = Time.at(t.to_seconds)
  "Day #{time.wday-Time.at(0).wday} #{time.hour}:#{time.min}"
end
  

def vehicle_counts(traf_dat,dt, start_day, stop_day,dir)
  dt = dt.to_seconds
  hsh = {}
  start_day.to_seconds.step(stop_day.to_seconds-1.seconds,dt) do |t|
    t = t.to_seconds
    hsh[time_str(t)] = traf_dat.traffic_in_period(t,t+dt,dir)
  end
end

def avg_vehicle_counts(traf_dat,dt,dir)
  all = vehicle_counts(traf_dat,dt,0.days,5.days,dir)
  avg = {}
  0.step(1.days.to_seconds,dt) do |t|
    avg[time_str(t)] = 0
    (0...5).each do |day|
      avg[time_str(t)] += all[time_str(day.days+t)]
    end
    avg[time_str(t)] /= 5
  end
  avg
end

def peak_volume_times(traf_dat,dt,dir)
  all = vehicle_counts(traf_dat,dt,0.days,5.days,dir)
  all.inverse[all.values.Max]
end