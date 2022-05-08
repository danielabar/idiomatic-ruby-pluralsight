# Idiomatic Ruby

My notes from Pluralsight [course](https://app.pluralsight.com/library/courses/ruby-idiomatic/table-of-contents).

[Ruby Docs](https://docs.ruby-lang.org/en/)

**Convenience for VS Code**

Install [Code Runner](https://marketplace.visualstudio.com/items?itemName=formulahendry.code-runner) extension. Then from any Ruby file hit control + alt + n to run the file.

Add to `settings.json`:

```json
"code-runner.clearPreviousOutput": true,
```

## Blocks, Conditionals, and Symbols

## Blocks Coding

Will be using [movies.csv](project/movies.csv).

Would like to answer questions about movie library such as "What comedy movies do I own"? Will write some code to make sense of the data.

First attempt at reading file [movies_1.rb](project/movies_1.rb).

This first attempt is the procedural approach:

Use `begin`/`ensure` blocks when some code needs to run, regardless of whether previous code was successful or failed.

```ruby
file_handle = File.open("movies.csv", "r")

begin
  lines = file_handle.readlines
  # BOOM - suppose some error occurs...
ensure
  file_handle.close
end
```

But code isn't very focused. Let's use Lambda to improve it, aka anonymous function.

Second attempt at reading file [movies_2.rb](project/movies_2.rb).

Define anonymous function and then use it:

```ruby
read_all_lines = lambda { |file_handle| file_handle.readlines }
lines = File.open("project/movies.csv", "r", &read_all_lines)
pp lines
```

Improvement, define anonymous function right in the place where we use it. This is what blocks do in Ruby.

[movies_3.rb](project/movies_3.rb)

```ruby
# 1. Read the movies.csv file
# Ruby will pass the anonymous function in as the third argument to File.open
# Now definition of anon function and usage is in same place, making intention of code more clear
lines = File.open("project/movies.csv", "r") do |file_handle|
  file_handle.readlines
end

pp lines
```

### Blocks Details

Convenient anonymous functions. Common use cases include:

**Setting up and tearing down context**, eg: don't want to worry about the details of how to trigger the beginning and ending of a transaction. Just want to specify what would like to happen in the transaction:

```ruby
database.transaction do
  from_account.subtract_balance(100.0)
  to_account.add_balance(100.0)
end
```

**Asynchronous callbacks**, eg: button in UI and expecting to receive a network message from another process. Pass a block to the code that manages those messages/events:

```ruby
button.on_click do |click_event|
  create_new_user
end
```

**Apply function multiple times**

```ruby
[1, 2, 3, 4].map do |int|
  int * 2
end
# => [2, 4, 6, 8]
```

### Conditionals Coding

[movies_4.rb](project/movies_4.rb)

Where we left off, after reading in `lines` from `File.open`, notice that `lines` is an array, where each entry is a string.

```ruby
lines = File.open("project/movies.csv", "r") do |file_handle|
  file_handle.readlines
end

pp lines
```

Now, we'd like to turn each line into an array of values: `["title", "director", ...]`. This is done by iterating over each line, and splitting on `","`, which returns an array of individual string values from the line:

```ruby
lines = File.open("project/movies.csv", "r") do |file_handle|
  file_handle.readlines
end

rows = []
lines.each do |line|
  row = line.split(",")
  rows.push(row)
end

pp rows.first
# ["title", "release date", "director", "genre\n"]
```

ISSUE: Last value contains new line char `\n`. To fix this, use [chomp](https://docs.ruby-lang.org/en/2.7.0/String.html#method-i-chomp) method of String which returns a new string with leading and trailing whitespace removed:

```ruby
lines = File.open("project/movies.csv", "r") do |file_handle|
  file_handle.readlines
end

rows = []
lines.each do |line|
  row = line.chomp.split(",")
  rows.push(row)
end

pp rows.first
# ["title", "release date", "director", "genre"]
```

There's an even easier way to add a value to the list (above does it in two lines, one to create a `row` object, and another to push it onto the `rows` array). Use shovel operator `<<` to add a value directly to list in one line:

```ruby
lines = File.open("project/movies.csv", "r") do |file_handle|
  file_handle.readlines
end

rows = []
lines.each do |line|
  rows << line.chomp.split(",")
end

pp rows.first
# ["title", "release date", "director", "genre"]
```

Now we have a list of rows, each containing a list of values. But we don't want a list of header values. What we want is a list of movies, with the header line matched against each value, i.e. a list of hashes like this:

```ruby
{"title" => "Star WArs...", "director" => "George...", ...}
```

To do this, iterate over the `rows` from the file, capture the first row in a `headers` array. Headers is initialized to nil and only populated if its currently nil. Then populate remainder of `movies` array with result of running [zip](https://docs.ruby-lang.org/en/2.7.0/Array.html#method-i-zip) method on the `headers` array, passing in the current data `row`.

`zip` operates on an array, and matches it up with the values you pass to it, simple example:

```ruby
headers = ["title", "release date", "director", "genre"]
a_row = ["Star Wars Episode IV: A New Hope", "1977-05-25", "George Lucas", "Science Fiction"]
zipped = headers.zip(a_row)
zipped
# [["title", "Star Wars Episode IV: A New Hope"], ["release date", "1977-05-25"], ["director", "George Lucas"], ["genre", "Science Fiction"]]
```

So processing the movies list we now have:

```ruby
lines = File.open("project/movies.csv", "r") do |file_handle|
  file_handle.readlines
end

rows = []
lines.each do |line|
  rows << line.chomp.split(",")
end

p rows.first
# ["title", "release date", "director", "genre"]

movies = []
headers = nil
rows.each do |row|
  if headers.nil?
    headers = row
  else
    movies << headers.zip(row)
  end
end

p movies.first
# [["title", "Star Wars Episode IV: A New Hope"], ["release date", "1977-05-25"], ["director", "George Lucas"], ["genre", "Science Fiction"]]
```

However, this makes the `movies` array contain a list of lists, we really want a hash. Use the [Hash](https://docs.ruby-lang.org/en/2.7.0/Hash.html) class to convert the list of pairs into a Hash object. See the `Public Class Methods` in the Hash docs for example of passing list of lists to constructor:

```ruby
lines = File.open("project/movies.csv", "r") do |file_handle|
  file_handle.readlines
end

rows = []
lines.each do |line|
  rows << line.chomp.split(",")
end

p rows.first
# ["title", "release date", "director", "genre"]

movies = []
headers = nil
rows.each do |row|
  if headers.nil?
    headers = row
  else
    movies << Hash[headers.zip(row)]
  end
end

p movies.first
# {"title"=>"Star Wars Episode IV: A New Hope", "release date"=>"1977-05-25", "director"=>"George Lucas", "genre"=>"Science Fiction"}
```

Watch out: If input csv file has empty line at end, last entry in movies may be a hash of nil values:

```ruby
p movies.last
# {"title"=>nil, "release date"=>nil, "director"=>nil, "genre"=>nil}
```

To prevent nil values, wrap entire row processing logic in an `!empty?` check on each individual `row`:

```ruby
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
  if !row.empty?
    if headers.nil?
      headers = row
    else
      movies << Hash[headers.zip(row)]
    end
  end
end

p movies.first
# {"title"=>"Star Wars Episode IV: A New Hope", "release date"=>"1977-05-25", "director"=>"George Lucas", "genre"=>"Science Fiction"}

p movies.last
# {"title"=>"The Matrix", "release date"=>"1999-03-31", "director"=>"Wachowskis", "genre"=>"Action"}
```

ISSUE: Code is getting messy -> nested conditionals makes it difficult for other people to understand what code is doing.

Get rid of "if not row empty" check with `unless`:

```ruby
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
  unless row.empty?
    if headers.nil?
      headers = row
    else
      movies << Hash[headers.zip(row)]
    end
  end
end

p movies.first
# {"title"=>"Star Wars Episode IV: A New Hope", "release date"=>"1977-05-25", "director"=>"George Lucas", "genre"=>"Science Fiction"}

p movies.last
# {"title"=>"The Matrix", "release date"=>"1999-03-31", "director"=>"Wachowskis", "genre"=>"Action"}
```

A little easier to read but still have messy nested conditionals.

Paradigm shift: Rather than thinking of "only do something when row is not empty", think of "skipping rows that are empty". Ruby allows this by adding an `if` statement to the end of an expression.

eg, will only run expression on the left if condition on the right is true:

```ruby
# in the middle of an each loop
# only run `next` if `row.empty?` is true
next if row.empty?
```

The expression `next if row.empty?` reads like English "skip this row if its empty".

Guard clauses very common in Ruby code. Example can be used to return early from a method:

```ruby
return nil unless n > 0
```

Use this to replace `unless` conditional. Will use `next` keyword since we're in a method:

```ruby
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
```

### Conditionals Details

TBD...