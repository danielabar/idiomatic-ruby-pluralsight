require 'csv'
movies = CSV.read('project_symbols/movies.csv', :headers => true, :header_converters => :symbol, :skip_blanks => true)

p movies[9]