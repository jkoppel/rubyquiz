$genres = ["Blues","Classic Rock","Country","Dance","Disco","Funk",
  "Grunge","Hip-Hop","Jazz","Metal","New Age","Oldies",
  "Other","Pop","R&B","Rap","Reggae","Rock","Techno",
  "Industrial","Alternative","Ska","Death Metal","Pranks",
  "Soundtrack","Euro-Techno","Ambient","Trip-Hop","Vocal",
  "Jazz+Funk","Fusion","Trance","Classical","Instrumental",
  "Acid","House","Game","Sound Clip","Gospel","Noise",
  "AlternRock","Bass","Soul","Punk","Space","Meditative",
  "Instrumental Pop","Instrumental Rock","Ethnic","Gothic",
  "Darkwave","Techno-Industrial","Electronic","Pop-Folk",
  "Eurodance","Dream","Southern Rock","Comedy","Cult","Gangsta",
  "Top 40","Christian Rap","Pop/Funk","Jungle",
  "Native American","Cabaret","New Wave","Psychadelic","Rave",
  "Showtunes","Trailer","Lo-Fi","Tribal","Acid Punk",
  "Acid Jazz","Polka","Retro","Musical","Rock & Roll",
  "Hard Rock","Folk","Folk-Rock","National Folk","Swing",
  "Fast Fusion","Bebob","Latin","Revival","Celtic","Bluegrass",
  "Avantgarde","Gothic Rock","Progressive Rock",
  "Psychedelic Rock","Symphonic Rock","Slow Rock","Big Band",
  "Chorus","Easy Listening","Acoustic","Humour","Speech",
  "Chanson","Opera","Chamber Music","Sonata","Symphony",
  "Booty Bass","Primus","Porn Groove","Satire","Slow Jam",
  "Club","Tango","Samba","Folklore","Ballad","Power Ballad",
  "Rhythmic Soul","Freestyle","Duet","Punk Rock","Drum Solo",
  "A capella","Euro-House","Dance Hall"]


file = File.new(ARGV[0].chomp)

tag, song, artist, album, year, comment, genre =
  file.read[-128..-1].unpack("A3A30A30A30A4A30C")

file.close

track = nil

genre = $genres[genre.to_i]

if comment[28] == 0
  track = comment[29]
  comment = comment[0..27]
end

if tag == "TAG"
  [:song, :artist, :album, :track, :year, :comment, :genre].each do |sym|
    puts sym.to_s.capitalize + ": " + eval(sym.id2name).to_s
  end
else
  puts "Did not find ID3v1 tags."
end