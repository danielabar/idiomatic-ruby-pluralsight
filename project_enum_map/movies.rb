require 'csv'
require_relative 'movie'

rows = CSV.read('project_enum_map/movies.csv', :headers => true, :header_converters => :symbol, :skip_blanks => true)

movies = rows.map { |row| Movie.new(row) }

pp movies.last