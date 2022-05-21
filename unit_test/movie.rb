require 'date'

class Movie
  attr_reader :director, :genre, :release_date, :rotten_tomatoes, :title

  def initialize(csv_row)
    @director = csv_row[:director]
    @genre = csv_row[:genre]
    @release_date = Date.parse(csv_row[:release_date])
    @rotten_tomatoes = csv_row[:rotten_tomatoes].to_i
    @title = csv_row[:title]
  end
end
