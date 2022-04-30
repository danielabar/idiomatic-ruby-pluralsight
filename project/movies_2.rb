# 1. Read the movies.csv file
# let someone else deal with details of opening file, reading, and ensuring it gets closed
# labmda/anon function receives a file handle and reads lines from it
read_all_lines = lambda { |file_handle| file_handle.readlines }

# the anon function can be passed to File.open as a third parameter,
# this is how we can tell File.open what to do with the file
# File.open will handle opening file and guaranteeing that the file will be closed
lines = File.open("project/movies.csv", "r", &read_all_lines)

# print out the lines just to verify program is working
pp lines

# 2. Parse the data into a set of movies

# 3. Find out how many movies I have in each genre

# 4. Show a list of all the titles directed by George Lucas