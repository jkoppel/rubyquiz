####Door prize picekr for LSRC. The program creates persistance by modifying its
####own source code.
####Command line usage: Without arguments, it runs the name picker
####With the -a argument, combined with the optional -o and -t arguments,
####it adds an attendee's name, organization, and hometown respectively to the program
require 'tk'
require 'enumerator'

$attendees = []
$organization = {}
$hometown = {}

$previous_winners = [nil]


###Adds code_str to this source file right before Tk::mainloop is invoked
def add_code(code_str)
  File.open($0, "a") do |f|
    f.puts code_str
  end
end

class Array
  def first_satisfies_i
    each_with_index {|el, i| return i if yield el}
    nil
  end
  
  def map_with_index
    mapped = []
    each_with_index {|el, i| mapped[i] = yield(el,i)}
    mapped
  end
end

def get_arg(name)
  arg_proc = proc {|arg| arg =~ /^-/}
   if (i = ARGV.index name)
    ARGV[(i+1)..((j=ARGV[(i+1)..-1].first_satisfies_i(&arg_proc)) ? i+j : -1)
      ].join(' ')
  end
end

###Code to check and process people being added from the command line
unless ARGV==[]
  name, org, town = ['-a','-o','-t'].map{|n| get_arg n}
  add_code <<-EOC
  
    $attendees << #{name.inspect}
    $organization[#{name.inspect}] = #{org.inspect}
    $hometown[#{name.inspect}] = #{town.inspect}
  EOC
  exit
end

class TkVariable
  ###Makes updating values as easy as it should be
  def []=(*args)
    v = self.value
    v[*args[0...-1]] = args.last
    self.value = v
  end
end

###Simulates a user typing text into a console
###The only way I could get it to wait for the typing to finish before
###continuing was to have it yield when done
def type(tkvar, text, sleep_t=0.05)
  Thread.new(tkvar, text) do |tkvar, text|
    until text.empty?
      sleep sleep_t
      tkvar.value, text[0,1] = tkvar.value+text[0,1], ""
    end
    yield
  end
end

def char_fly(tkvars, char_pos, dest_pos)
  incr =(dest_pos.to_f-char_pos)/(tkvars.length-1)
  c = tkvars.last.value[char_pos, 1]
  return if " "==c
  Thread.new(tkvars, char_pos, incr, c) do |tkvars, char_in, incr, c|
    tkvars.reverse.each_cons(2) do |tkvar_prev, tkvar|
      tkvar_prev[char_in.round, 1] = ' '
      char_in += incr
      tkvar[char_in.round, 1] = c
      sleep 0.1
    end
  end
end

root = TkRoot.new {
  title 'Lone Star Ruby Conf Door Prize Picker'
  background '#000000'}
TkMessage.new(root){
  background '#000000'
  borderwidth 0
  justify 'center'
  font 'courier'
  foreground '#C0C0C0'
  text <<EOD
	    .+                  
	    +h:                 
	   -shh`                
	  `shhhs                
`........./hhhhy---:--::::.     
`:shhhhyyyyyssyhhhhhhhys/`      
   `:shhhhyo+oyhhhhhy+.         
      `/syyyhhhhyyy:            
       `ohhhhhyssoy:            
       /yhhhdhhhysyh:           
      .shhyo- `:oyhhh`          
      oho-        -+ys          
     -:`             -.         
EOD
}.grid



content_frame = TkFrame.new(root){
  background '#000000'
  grid{rowspan 60; colspan '100'; sticky "ew"}}

##Holds a pseudo-console
console_frame = TkFrame.new(content_frame) {
  background '#000000'
  width 100
  grid{rowspan 100; colspan '100'; sticky "ew"}}
console_var = TkVariable.new " "*100
console = TkLabel.new(console_frame){
  background '#000000'
  foreground '#C0C0C0'
  justify 'left'
  font TkFont.new('Courier'){size 40}
  grid{rowspan 100; colspan '100'; sticky "ew"}
  height 7
}.textvariable(console_var)

##Holds the list that scrolls all the attendees names
list_frame = TkFrame.new(content_frame)  {
  background '#000000'
  grid{rowspan 100; colspan '100'; sticky "ew"}}
list = TkListbox.new(list_frame){
  background '#000000'
  foreground '#C0C0C0'
  borderwidth 0
  selectforeground '#000000'
  selectbackground '#C0C0C0'
  highlightthickness 0
  width 75
  font TkFont.new('Courier'){size 40}
  listvariable [' ']*10
  height 10
}

#Displays the word "scanning" when the list of attendees scrolled by
#There is significant flicker involved with this method, as everything is drawn as soon
#as I programmatically make the change.
#I was unable to remove the flicker (perhaps by suspending drawng routines, but
#could not find the class responsible in the docs). I had signicant trouble getting updating
#the value of #the listvariable to work; replacing the listvariable worked but was very slow.
#This approach is the best I came up with.
scanning_display = TkListbox.new(list_frame){
  foreground '#000000'
  background '#000000'
  highlightthickness 0
  borderwidth 0
  width 25
  font TkFont.new('Courier'){size 40}
  listvariable [' ']*10
  height 10}
  
flying_text_frame = TkFrame.new(content_frame) {
  background '#000000'
  width 100}
  
flying_textboxes = ([nil]*10).map {
  [(v=TkVariable.new(" "*100)),
    TkEntry.new(flying_text_frame){
      background '#000000'
      foreground '#C0C0C0'
      borderwidth 0
      font TkFont.new('Courier'){size 40}
      width 100
      grid{rowspan 100; colspan '100'; sticky "ew"}
    }.textvariable(v)]}.map{|arr|arr[0]}

TkGrid.grid(list, scanning_display)

##The main procedure of the program
run_picker = proc do
  if $ran
    return
  else
    $ran = true
  end
  $attendees = $attendees.sort_by {|n| n.split.reverse.join(' ')}
  type(console_var,"\n") do
    sleep 2
    console_var.value += "Why do you wake me, mortal?\n>"
    sleep 2; type(console_var, "I seek your wisdom and guidance.\n") do
      sleep 2; console_var.value += "What perplexes you?\n>"; sleep 2
      type(console_var, "Tell me the one most worthy of "+
          "receiving this prize.\n") do
        sleep 2
        console_var.value += "Very well; "
        sleep 0.5
        console_var.value += "the time is right for that decision."
        lvar = TkVariable.new $attendees
        sleep 1
        list.listvariable lvar
        scanning_display.listvariable(TkVariable.new(["scanning"]))
        scanning_display.itemconfigure(0, "background"=> "#C0C0C0")
        $attendees[0..-10].each_with_index do |el, i|
          list.yview(i)
          list.selection_set(i)
          sleep 0.01
        end
        list_frame.ungrid
        sleep 0.2
        console_var.value += "\nI have found your worthy candidate." + 
          " Watch and let the mystery reveal itself."
        sleep 3
        console_frame.ungrid
        chosen = nil
        chosen = $attendees[rand($attendees.length)
          ] while $previous_winners.include? chosen
        scrambled = chosen.split(//).map_with_index{|el, i|
          [rand,el,i]}.sort.map{|arr|arr[1..2]}
        scrambled_str = scrambled.map{|el| el[0]}.join
        flying_textboxes.last.value = " "*(50-scrambled_str.length/2)+
          scrambled_str
        flying_text_frame.grid
        sleep 1
        until flying_textboxes.first.value.include? chosen
          ci=rand(scrambled_str.length)
          char_fly(flying_textboxes,  (50-scrambled_str.length/2)+ci,
            (50-scrambled_str.length/2)+scrambled[ci][1])
          sleep 0.1
        end
        t = $hometown[chosen]
        o = $organization[chosen]
        flying_textboxes[1][50-t.length/2,t.length] = t if t
        flying_textboxes[2][50-o.length/2,o.length] = o if o
        add_code <<-EOC
        
          $previous_winners << #{chosen.inspect}
        EOC
      end
    end
  end
end

#run_picker = proc { type(console_var, "I seek your wisdom and guidance.\n").join}

root.bind('FocusIn', &run_picker)
at_exit {Tk.mainloop}  
    $attendees << "Leith Kucha"
    $organization["Leith Kucha"] = nil
    $hometown["Leith Kucha"] = "Kettlerville, FL"
  
    $attendees << "Chowdhury Carranco"
    $organization["Chowdhury Carranco"] = nil
    $hometown["Chowdhury Carranco"] = "Gaskeyville, CA"
  
    $attendees << "Dahley Osby"
    $organization["Dahley Osby"] = "Tuley and Boyland Consulting, LLC"
    $hometown["Dahley Osby"] = "Mosconeville, FL"
  
    $attendees << "Schlechten Shalwani"
    $organization["Schlechten Shalwani"] = nil
    $hometown["Schlechten Shalwani"] = "Casisville, IL"
  
    $attendees << "Stivason Hentschel"
    $organization["Stivason Hentschel"] = "Spath and Trowel Consulting, LLC"
    $hometown["Stivason Hentschel"] = "Suskiville, IL"
  
    $attendees << "Double Nylander"
    $organization["Double Nylander"] = "Weimer and Regn Consulting, LLC"
    $hometown["Double Nylander"] = "Levitonville, IL"
  
    $attendees << "Helgason Mccastle"
    $organization["Helgason Mccastle"] = nil
    $hometown["Helgason Mccastle"] = "Stallionville, MA"        
          $previous_winners << "Dahley Osby"
        
          $previous_winners << "Double Nylander"
        
          $previous_winners << "Schlechten Shalwani"
        
          $previous_winners << "Leith Kucha"
        
          $previous_winners << "Chowdhury Carranco"
        
          $previous_winners << "Stivason Hentschel"
        
          $previous_winners << "Helgason Mccastle"
  
    $attendees << "Wehrenberg Carrigg"
    $organization["Wehrenberg Carrigg"] = nil
    $hometown["Wehrenberg Carrigg"] = "Vansteenwykville, CA"
  
    $attendees << "Brosseau Halen"
    $organization["Brosseau Halen"] = nil
    $hometown["Brosseau Halen"] = "Pettasville, MA"
  
    $attendees << "Ourso Tajudeen"
    $organization["Ourso Tajudeen"] = nil
    $hometown["Ourso Tajudeen"] = "Cosgrayville, MA"
  
    $attendees << "Ghramm Alfaro"
    $organization["Ghramm Alfaro"] = nil
    $hometown["Ghramm Alfaro"] = "Odeaville, NY"
  
    $attendees << "Wald Edwads"
    $organization["Wald Edwads"] = nil
    $hometown["Wald Edwads"] = "Steinbacherville, CA"
  
    $attendees << "Matros Silcox"
    $organization["Matros Silcox"] = nil
    $hometown["Matros Silcox"] = "Degenaroville, NY"
  
    $attendees << "Clance Christoffer"
    $organization["Clance Christoffer"] = "Roznowski and Wool Consulting, LLC"
    $hometown["Clance Christoffer"] = "Cambellville, FL"
  
    $attendees << "Altavilla Chancey"
    $organization["Altavilla Chancey"] = nil
    $hometown["Altavilla Chancey"] = "Bearville, MA"
  
    $attendees << "Orosz Floran"
    $organization["Orosz Floran"] = nil
    $hometown["Orosz Floran"] = "Lowdenville, AZ"
  
    $attendees << "Wantland Lerma"
    $organization["Wantland Lerma"] = nil
    $hometown["Wantland Lerma"] = "Loverichville, MO"
  
    $attendees << "Reader Salos"
    $organization["Reader Salos"] = nil
    $hometown["Reader Salos"] = "Extineville, NY"
  
    $attendees << "Degolier Jerger"
    $organization["Degolier Jerger"] = nil
    $hometown["Degolier Jerger"] = "Elfstromville, IL"
  
    $attendees << "Carey Kristek"
    $organization["Carey Kristek"] = "Lamparski and Gettle Consulting, LLC"
    $hometown["Carey Kristek"] = "Bottsville, AR"
  
    $attendees << "Prochak Canerday"
    $organization["Prochak Canerday"] = nil
    $hometown["Prochak Canerday"] = "Nesserville, NY"
  
    $attendees << "Ramsdale Himmelsbach"
    $organization["Ramsdale Himmelsbach"] = "Koistinen and Uphaus Consulting, LLC"
    $hometown["Ramsdale Himmelsbach"] = "Malasville, IL"
  
    $attendees << "Hartlein Inagaki"
    $organization["Hartlein Inagaki"] = "Nishiyama and Symkowick Consulting, LLC"
    $hometown["Hartlein Inagaki"] = "Kohnerville, IL"
  
    $attendees << "Rote Madlem"
    $organization["Rote Madlem"] = "Hochhalter and Bruemmer Consulting, LLC"
    $hometown["Rote Madlem"] = "Zinniville, CA"
  
    $attendees << "Olivers Maser"
    $organization["Olivers Maser"] = "Panchik and Prak Consulting, LLC"
    $hometown["Olivers Maser"] = "Courseaultville, AR"
  
    $attendees << "Sayle Stribble"
    $organization["Sayle Stribble"] = nil
    $hometown["Sayle Stribble"] = "Jaretville, NY"
  
    $attendees << "Reda Ferrill"
    $organization["Reda Ferrill"] = nil
    $hometown["Reda Ferrill"] = "Lampeyville, FL"
  
    $attendees << "Divalerio Scordato"
    $organization["Divalerio Scordato"] = "Saulsbury and Vanstone Consulting, LLC"
    $hometown["Divalerio Scordato"] = "Spagnuoloville, IL"
  
    $attendees << "Finical Waskiewicz"
    $organization["Finical Waskiewicz"] = nil
    $hometown["Finical Waskiewicz"] = "Saganville, MO"
  
    $attendees << "Gopen Dorson"
    $organization["Gopen Dorson"] = "Charlie and Tamplin Consulting, LLC"
    $hometown["Gopen Dorson"] = "Zozayaville, FL"
  
    $attendees << "Rossi Lissard"
    $organization["Rossi Lissard"] = "Balda and Slomer Consulting, LLC"
    $hometown["Rossi Lissard"] = "Tarkowskiville, AR"
  
    $attendees << "Overholser Wiinikainen"
    $organization["Overholser Wiinikainen"] = "Mcneill and Struzik Consulting, LLC"
    $hometown["Overholser Wiinikainen"] = "Cabralesville, IL"
  
    $attendees << "Falis Raghunandan"
    $organization["Falis Raghunandan"] = "Genao and Kreinhagen Consulting, LLC"
    $hometown["Falis Raghunandan"] = "Hammangville, NY"
  
    $attendees << "Vasmadjides Najjar"
    $organization["Vasmadjides Najjar"] = "Sista and Vanzant Consulting, LLC"
    $hometown["Vasmadjides Najjar"] = "Pericoville, MO"
  
    $attendees << "Severo Elrod"
    $organization["Severo Elrod"] = "Guell and Finazzo Consulting, LLC"
    $hometown["Severo Elrod"] = "Pagliariniville, CA"
  
    $attendees << "Zecca Marotte"
    $organization["Zecca Marotte"] = "Marxen and Shumaker Consulting, LLC"
    $hometown["Zecca Marotte"] = "Burgessville, IL"
  
    $attendees << "Heitger Cichon"
    $organization["Heitger Cichon"] = "Placker and Nekola Consulting, LLC"
    $hometown["Heitger Cichon"] = "Kenrickville, AZ"
  
    $attendees << "Gatling Konma"
    $organization["Gatling Konma"] = nil
    $hometown["Gatling Konma"] = "Krupinskiville, NY"
  
    $attendees << "Stewardson Standing"
    $organization["Stewardson Standing"] = nil
    $hometown["Stewardson Standing"] = "Palasville, FL"
  
    $attendees << "Paulson Luongo"
    $organization["Paulson Luongo"] = "Redlon and Hopkins Consulting, LLC"
    $hometown["Paulson Luongo"] = "Poppemaville, CA"
  
    $attendees << "Mcandrew Radom"
    $organization["Mcandrew Radom"] = nil
    $hometown["Mcandrew Radom"] = "Feltsville, IL"
  
    $attendees << "Klatte Doria"
    $organization["Klatte Doria"] = "Bachleda and Preusser Consulting, LLC"
    $hometown["Klatte Doria"] = "Copenville, MO"
  
    $attendees << "Villacana Slaff"
    $organization["Villacana Slaff"] = "Bernett and Griffon Consulting, LLC"
    $hometown["Villacana Slaff"] = "Belfortville, AZ"
  
    $attendees << "Kutner Krzewinski"
    $organization["Kutner Krzewinski"] = "Abernethy and Cagnon Consulting, LLC"
    $hometown["Kutner Krzewinski"] = "Chailleville, NY"
  
    $attendees << "Woltz Hasfjord"
    $organization["Woltz Hasfjord"] = nil
    $hometown["Woltz Hasfjord"] = "Keithlyville, NY"
  
    $attendees << "Dimpson Bellafiore"
    $organization["Dimpson Bellafiore"] = nil
    $hometown["Dimpson Bellafiore"] = "Rentonville, NY"
  
    $attendees << "Schoville Heimann"
    $organization["Schoville Heimann"] = nil
    $hometown["Schoville Heimann"] = "Garroville, IL"
  
    $attendees << "Teske Zimmer"
    $organization["Teske Zimmer"] = "Longabaugh and Heningburg Consulting, LLC"
    $hometown["Teske Zimmer"] = "Rabehlville, AR"
  
    $attendees << "Sajor Ohayon"
    $organization["Sajor Ohayon"] = nil
    $hometown["Sajor Ohayon"] = "Tonderville, CA"
  
    $attendees << "Isabella Lao"
    $organization["Isabella Lao"] = "Whitfill and Polson Consulting, LLC"
    $hometown["Isabella Lao"] = "Hirotaville, AZ"
  
    $attendees << "Gaber Marmolejo"
    $organization["Gaber Marmolejo"] = nil
    $hometown["Gaber Marmolejo"] = "Foxeville, MO"
  
    $attendees << "Fergerson Tartaglino"
    $organization["Fergerson Tartaglino"] = "Nick and Yovanovich Consulting, LLC"
    $hometown["Fergerson Tartaglino"] = "Mintzville, AR"
  
    $attendees << "Keat Kudla"
    $organization["Keat Kudla"] = "Curra and Deveney Consulting, LLC"
    $hometown["Keat Kudla"] = "Kirmerville, TX"
  
    $attendees << "Dunnegan Besaw"
    $organization["Dunnegan Besaw"] = "Avenoso and Tuzzolo Consulting, LLC"
    $hometown["Dunnegan Besaw"] = "Chownville, FL"
  
    $attendees << "Barrom Mayse"
    $organization["Barrom Mayse"] = nil
    $hometown["Barrom Mayse"] = "Anguloville, IL"
  
    $attendees << "Branker Deonarine"
    $organization["Branker Deonarine"] = "Casarz and Waggy Consulting, LLC"
    $hometown["Branker Deonarine"] = "Mansoville, TX"
  
    $attendees << "Hackenberg Silberg"
    $organization["Hackenberg Silberg"] = nil
    $hometown["Hackenberg Silberg"] = "Aguiarville, NY"
  
    $attendees << "Schiffman Siddiq"
    $organization["Schiffman Siddiq"] = nil
    $hometown["Schiffman Siddiq"] = "Whittierville, MO"
  
    $attendees << "Cromeans Vigorito"
    $organization["Cromeans Vigorito"] = nil
    $hometown["Cromeans Vigorito"] = "Pohlmannville, MI"
  
    $attendees << "Quickle Vinas"
    $organization["Quickle Vinas"] = "Segars and Mahan Consulting, LLC"
    $hometown["Quickle Vinas"] = "Jaquesville, MA"
  
    $attendees << "Dechick Eggers"
    $organization["Dechick Eggers"] = nil
    $hometown["Dechick Eggers"] = "Sciulliville, NY"
  
    $attendees << "Oberst Looper"
    $organization["Oberst Looper"] = nil
    $hometown["Oberst Looper"] = "Rickettsville, CA"
  
    $attendees << "Teaff Blackerby"
    $organization["Teaff Blackerby"] = nil
    $hometown["Teaff Blackerby"] = "Hilpertville, AR"
  
    $attendees << "Brett Lutao"
    $organization["Brett Lutao"] = "Tak and Speagle Consulting, LLC"
    $hometown["Brett Lutao"] = "Civcciville, FL"
  
    $attendees << "Hedegore Taneja"
    $organization["Hedegore Taneja"] = nil
    $hometown["Hedegore Taneja"] = "Masentenville, MO"
  
    $attendees << "Bhatnagar Silveria"
    $organization["Bhatnagar Silveria"] = nil
    $hometown["Bhatnagar Silveria"] = "Korandoville, AZ"
  
    $attendees << "Obryan Feldkamp"
    $organization["Obryan Feldkamp"] = nil
    $hometown["Obryan Feldkamp"] = "Dollville, FL"
  
    $attendees << "Primo Perino"
    $organization["Primo Perino"] = nil
    $hometown["Primo Perino"] = "Glodville, FL"
  
    $attendees << "Caraker Ledsome"
    $organization["Caraker Ledsome"] = nil
    $hometown["Caraker Ledsome"] = "Chindlundville, MO"
  
    $attendees << "Epp Fleurissaint"
    $organization["Epp Fleurissaint"] = nil
    $hometown["Epp Fleurissaint"] = "Menakerville, IL"
  
    $attendees << "Diede Lincourt"
    $organization["Diede Lincourt"] = nil
    $hometown["Diede Lincourt"] = "Dupontville, NY"
  
    $attendees << "Kulow Bournes"
    $organization["Kulow Bournes"] = nil
    $hometown["Kulow Bournes"] = "Cheryville, FL"
  
    $attendees << "Reilley Spittler"
    $organization["Reilley Spittler"] = "Sliger and Oiler Consulting, LLC"
    $hometown["Reilley Spittler"] = "Tepferville, TX"
  
    $attendees << "Montierth Negus"
    $organization["Montierth Negus"] = nil
    $hometown["Montierth Negus"] = "Hottelville, CA"
  
    $attendees << "Armato Sabin"
    $organization["Armato Sabin"] = "Iuchs and Salameh Consulting, LLC"
    $hometown["Armato Sabin"] = "Gillardville, NY"
  
    $attendees << "Woolsey America"
    $organization["Woolsey America"] = "Maiden and Latzka Consulting, LLC"
    $hometown["Woolsey America"] = "Handinville, MO"
  
    $attendees << "Kammer Bink"
    $organization["Kammer Bink"] = nil
    $hometown["Kammer Bink"] = "Chivaletteville, MI"
  
    $attendees << "Girand Vost"
    $organization["Girand Vost"] = nil
    $hometown["Girand Vost"] = "Johannesenville, MA"
  
    $attendees << "Ziler Kantrowitz"
    $organization["Ziler Kantrowitz"] = nil
    $hometown["Ziler Kantrowitz"] = "Satreville, AZ"
  
    $attendees << "Sweat Malkoski"
    $organization["Sweat Malkoski"] = "Ferraiz and Mare Consulting, LLC"
    $hometown["Sweat Malkoski"] = "Caneteville, FL"
  
    $attendees << "Hickmon Laury"
    $organization["Hickmon Laury"] = nil
    $hometown["Hickmon Laury"] = "Sabatasoville, MA"
  
    $attendees << "Costley Strazza"
    $organization["Costley Strazza"] = nil
    $hometown["Costley Strazza"] = "Panagakosville, NY"
  
    $attendees << "Kata Countess"
    $organization["Kata Countess"] = "Kohel and Duponte Consulting, LLC"
    $hometown["Kata Countess"] = "Salsmanville, AZ"
  
    $attendees << "Sugimoto Hultgren"
    $organization["Sugimoto Hultgren"] = nil
    $hometown["Sugimoto Hultgren"] = "Ernstesville, MI"
  
    $attendees << "Fugitt Tear"
    $organization["Fugitt Tear"] = nil
    $hometown["Fugitt Tear"] = "Leissville, NY"
  
    $attendees << "Dial Hillebrand"
    $organization["Dial Hillebrand"] = "Tuffin and Opie Consulting, LLC"
    $hometown["Dial Hillebrand"] = "Rolinville, MA"
  
    $attendees << "Clamp Okoronkwo"
    $organization["Clamp Okoronkwo"] = "Gizzo and Rosenlof Consulting, LLC"
    $hometown["Clamp Okoronkwo"] = "Stealyville, MO"
  
    $attendees << "Miltz Hasha"
    $organization["Miltz Hasha"] = "Kooken and Granroth Consulting, LLC"
    $hometown["Miltz Hasha"] = "Underhillville, AR"
  
    $attendees << "Deng Schilling"
    $organization["Deng Schilling"] = nil
    $hometown["Deng Schilling"] = "Arvizoville, IL"
  
    $attendees << "Maag Ristig"
    $organization["Maag Ristig"] = "Deslaurier and Shewchuk Consulting, LLC"
    $hometown["Maag Ristig"] = "Fouhyville, FL"
  
    $attendees << "Davel Chisom"
    $organization["Davel Chisom"] = "Stoll and Hensen Consulting, LLC"
    $hometown["Davel Chisom"] = "Mummaville, FL"
  
    $attendees << "Alborn Shelpman"
    $organization["Alborn Shelpman"] = "Lorenzo and Apana Consulting, LLC"
    $hometown["Alborn Shelpman"] = "Baergville, CA"
  
    $attendees << "Dhosane Vanhauen"
    $organization["Dhosane Vanhauen"] = "Lollie and Macfarlane Consulting, LLC"
    $hometown["Dhosane Vanhauen"] = "Mehserleville, MA"
  
    $attendees << "Trickett Nest"
    $organization["Trickett Nest"] = nil
    $hometown["Trickett Nest"] = "Hubermanville, MO"
  
    $attendees << "Mortimer Zimerman"
    $organization["Mortimer Zimerman"] = nil
    $hometown["Mortimer Zimerman"] = "Whitikerville, MO"
  
    $attendees << "Koy Gelber"
    $organization["Koy Gelber"] = "Shandley and Grober Consulting, LLC"
    $hometown["Koy Gelber"] = "Bouzaville, TX"
  
    $attendees << "Jason Zweifel"
    $organization["Jason Zweifel"] = nil
    $hometown["Jason Zweifel"] = "Chirafisiville, TX"
  
    $attendees << "Leistner Tromblay"
    $organization["Leistner Tromblay"] = nil
    $hometown["Leistner Tromblay"] = "Edlundville, MA"
  
    $attendees << "Toney Edington"
    $organization["Toney Edington"] = "Leamy and Colebank Consulting, LLC"
    $hometown["Toney Edington"] = "Creseliousville, AR"
  
    $attendees << "Rebera Eliasen"
    $organization["Rebera Eliasen"] = nil
    $hometown["Rebera Eliasen"] = "Lyeville, CA"
        
          $previous_winners << "Branker Deonarine"
        
          $previous_winners << "Caraker Ledsome"
        
          $previous_winners << "Schoville Heimann"
        
          $previous_winners << "Fugitt Tear"
        
          $previous_winners << "Overholser Wiinikainen"
