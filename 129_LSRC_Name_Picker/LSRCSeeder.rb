File.open("names.dat") do |f|
	names = f.readlines.map{|l|l.split[0].capitalize}
	300.times do
		name = names[rand(names.length)] + " " + name = names[rand(names.length)]
		org = nil
		if rand(2)==1
			org = names[rand(names.length)] + " and " + names[rand(names.length)] + " Consulting, LLC"
		end
		home = names[rand(names.length)] + "ville, " + %w{MA CA NY MI FL MO AZ TX AR IL}.sort_by{rand}.first
		if org
			`ruby LSRCPicker.rb -a #{name} -o #{org} -t #{home}`
		else
			`ruby LSRCPicker.rb -a #{name} -t #{home}`
		end
	end
end