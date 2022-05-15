require 'csv'
movies = CSV.read('project_object/movies.csv', :headers => true, :header_converters => :symbol, :skip_blanks => true)

p movies[9]

# p movies[9].title
p movies[9][:title]

p movies[9][:release_date]
# p movies[9][:release_date].year

p movies[9][:rotten_tomatoes]
p movies[9][:rotten_tomatoes] / 100