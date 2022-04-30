# 1. Read the movies.csv file
# Ruby will pass the anonymous function in as the third argument to File.open
# Now definition of anon function and usage is in same place, making intention of code more clear
lines = File.open("project/movies.csv", "r") do |file_handle|
  file_handle.readlines
end

# print out the lines just to verify program is working
pp lines

# 2. Parse the data into a set of movies

# 3. Find out how many movies I have in each genre

# 4. Show a list of all the titles directed by George Lucas