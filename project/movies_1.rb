system("pwd")
# 1. Read the movies.csv file
# Start by opening the file
# Provide path to file, and indicate that we intend to read from file
file_handle = File.open("project/movies.csv", "r")

# Something could go wrong while reading, such as another process deletes the file
# Use begin/ensure block to make sure we can always clean up by closing the file
begin
  # read all lines from file and capture into a variable
  lines = file_handle.readlines
  # BOOM - suppose some error occurs...
ensure
  # ensure block: regardless if code in begin block succeeds or fails, run code here
  # remember to close the file to avoid memory leak
  file_handle.close
end

# print out the lines just to verify program is working
pp lines

# 2. Parse the data into a set of movies

# 3. Find out how many movies I have in each genre

# 4. Show a list of all the titles directed by George Lucas