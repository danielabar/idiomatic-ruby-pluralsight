lines = File.open("project/movies.csv", "r") do |file_handle|
  file_handle.readlines
end
p lines.last
# "\n"

rows = []
lines.each do |line|
  rows << line.chomp.split(",")
end

p rows.first
# ["title", "release date", "director", "genre"]

movies = []
headers = nil
rows.each do |row|
  next if row.empty?

  if headers.nil?
    headers = row
  else
    movies << Hash[headers.zip(row)]
  end
end

p movies.first
# {"title"=>"Star Wars Episode IV: A New Hope", "release date"=>"1977-05-25", "director"=>"George Lucas", "genre"=>"Science Fiction"}

p movies.last
# {"title"=>"The Matrix", "release date"=>"1999-03-31", "director"=>"Wachowskis", "genre"=>"Action"}