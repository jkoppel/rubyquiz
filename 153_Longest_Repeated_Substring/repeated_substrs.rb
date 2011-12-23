text = ARGF.read

substr_locs = {}

text.split(//).each_with_index do |c,idx|
  if substr_locs[c]
    substr_locs[c] << idx
  else
    substr_locs[c] = [idx]
  end
end

substr_locs.each_pair do |substr,locs|
  substr_locs.delete(substr) if locs.length == 1
end

len = 1
done = false
until done
  len += 1
  new_substr_locs = {}
  substr_locs.each_pair do |substr,locs|
    locs.each do |idx|
      s = text[idx,len]
      next if idx+len>text.length
      if new_substr_locs[s]
        new_substr_locs[s] << idx
      else
        new_substr_locs[s] = [idx]
      end
    end
  end
  ##Must reduce for the case where a substring overlaps itself
  new_substr_locs.each_key do |s|
    locs = new_substr_locs[s]
    idx = 1
    while idx < locs.length
      if locs[idx]-locs[idx-1] < len
        locs.delete_at(idx)
      else
        idx += 1
      end
    end
    new_substr_locs.delete(s) if locs.length == 1
  end
  unless new_substr_locs.keys.empty?
    substr_locs = new_substr_locs
  else
    done = true
  end
end
puts substr_locs.keys.first