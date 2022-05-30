require 'csv'
require_relative 'movie'

rows = CSV.read('project_enum_map/movies.csv', :headers => true, :header_converters => :symbol, :skip_blanks => true)

movies = rows.map { |row| Movie.new(row) }

with_rotten_tomatoes = movies.select { |movie| movie.rotten_tomatoes > 0 }

total_rotten_tomatoes = with_rotten_tomatoes.reduce(0.0) do |total, movie|
  total + movie.rotten_tomatoes
end

average_rotten_tomatoes = total_rotten_tomatoes / with_rotten_tomatoes.size
puts "Average Rotten Tomatoes Score: #{average_rotten_tomatoes}"

# Big releases during holidays?
movies_by_month = movies.group_by do |movie|
  movie.release_date.strftime("%B")
end
# {"January" => [movie, movie, movie...], "February" => [movie, movie, ...]}

count_by_month = movies_by_month.map do |month, list|
  [month, list.size]
end

count_by_month = count_by_month.sort_by(&:last).reverse

puts count_by_month.map { |pair| pair.join(": ")}.join("\n")