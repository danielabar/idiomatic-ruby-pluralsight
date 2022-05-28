require 'csv'
require_relative 'movie'

rows = CSV.read('project_enum_map/movies.csv', :headers => true, :header_converters => :symbol, :skip_blanks => true)

movies = rows.map { |row| Movie.new(row) }

with_rotten_tomatoes = movies.select { |movie| movie.rotten_tomatoes > 0 }

total_rotten_tomatoes = 0.0
with_rotten_tomatoes.each do |movie|
  total_rotten_tomatoes += movie.rotten_tomatoes
end

average_rotten_tomatoes = total_rotten_tomatoes / with_rotten_tomatoes.size
puts "Average Rotten Tomatoes Score: #{average_rotten_tomatoes}"
# Average Rotten Tomatoes Score: 80.6923076923077