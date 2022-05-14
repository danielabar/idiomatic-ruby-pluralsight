<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Idiomatic Ruby](#idiomatic-ruby)
  - [Blocks, Conditionals, and Symbols](#blocks-conditionals-and-symbols)
    - [Blocks Coding](#blocks-coding)
    - [Blocks Details](#blocks-details)
    - [Conditionals Coding](#conditionals-coding)
    - [Conditionals Details](#conditionals-details)
      - [Conditional Assignment](#conditional-assignment)
    - [Symbols Coding](#symbols-coding)
    - [Symbols Details](#symbols-details)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Idiomatic Ruby

My notes from Pluralsight [course](https://app.pluralsight.com/library/courses/ruby-idiomatic/table-of-contents).

[Ruby Docs](https://docs.ruby-lang.org/en/) - documents the Ruby language *and* the Ruby standard library that ships with every copy of Ruby.

I'm using `2.7.1`, instructor was on `2.1.5`.

**Convenience for VS Code**

Install [Code Runner](https://marketplace.visualstudio.com/items?itemName=formulahendry.code-runner) extension. Then from any Ruby file hit control + alt + n to run the file.

Add to `settings.json`:

```json
"code-runner.clearPreviousOutput": true,
```

## Blocks, Conditionals, and Symbols

### Blocks Coding

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

Ruby provides several different ways to do conditionals.

"Traditional" example, looks similar to other languages, detect even/odd numbers:

```ruby
if 4 % 2 == 0
  puts "4 is even"
else
  puts "4 is odd"
end
```

Rather than doing a calculation and testing for equality in the `if` condition, the preferred Ruby approach is to use a predicate method:

```ruby
if 4.even?
  puts "4 is even"
else
  puts "4 is odd"
end
```

**Predicate methods:** Should only return true/false, named with `?` at end. Don't have to use `?` but that is the convention. It indicates "this method is intended to return true or false".

Ruby allows putting the conditional at the end of a statement, which is useful in guard clauses:

```ruby
puts "4 is even" if 4.even?
```

However, conditionals at end of a long line can be easy to miss when someone is scanning through some code. Sometimes prefer the `if...end` form for clarity.

Can also use `unless` keyword. Useful when have a predicate method that checks for the *opposite* of the condition that is being looked at:

```ruby
puts "4 is even" unless 4.odd?
```

In the above example `if 4.even?` is more natural to read, but in some cases, `unless` will be a better fit.

**CAUTION:** NEVER use unless with negation because it requires too many "double-takes" to figure out when the condition will or will not fire:

```ruby
# BAD
puts "4 is even" unless !4.even?
```

#### Conditional Assignment

Useful for caching a value:

```ruby
def best_players
  @best_players ||= database.lookup
end
```

Typically used in a method. `best_players` method may get call many times, or never at all. If it's never called, don't want to make expensive db query. But if method called many times, only want to run db query once and save results.

Conditional assignment checks current value of variable on left, if it's `false` or `nil`, will run the expression on the right and assign result to the variable.

Any expression returns its last value, so conditional assignment can also be used with `begin...end` blocks, which allows caching a value that takes multiple steps to compute:

```ruby
def best_players
  @best_players ||= begin
    players = database.table(:players)
    sorted = players.order(:points)
    sorted.top(10)
  end
end
```

### Symbols Coding

Using data [movies.csv](project_symbols/movies.csv), and code [movies.rb](project_symbols/movies.rb)

Note it contains a movie name that has a comma in its name, so the title is enclosed in quotes:

```csv
title,release date,director,genre
Star Wars Episode IV: A New Hope,1977-05-25,George Lucas,Science Fiction
Star Wars Episode V: The Empire Strikes Back,1980-05-21,George Lucas,Science Fiction
Star Wars Episode VI: Return of the Jedi,1983-05-25,George Lucas,Science Fiction
Star Wars Episode I: The Phantom Menace,1999-05-19,George Lucas,Science Fiction
Star Wars Episode II: Attack of the Clones,2002-05-16,George Lucas,Science Fiction

Star Wars Episode III: Revenge of the Sith,2005-05-19,George Lucas,Science Fiction
Ghostbusters,1984-06-07,Ivan Reitman,Comedy
Back To The Future,1985-07-03,Robert Zemeckis,Science Fiction
The Matrix,1999-03-31,Wachowskis,Action
"20,000 Leagues Under the Sea",1954-12-23,RichardFleischer,Science Fiction
```

This breaks the parsing, current code:

```ruby
lines = File.open("project/movies.csv", "r") do |file_handle|
  file_handle.readlines
end

rows = []
lines.each do |line|
  rows << line.chomp.split(",")
end

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

p movies.last
```

Last movie has been parsed as:

```ruby
{"title"=>"\"20", "release date"=>"000 Leagues Under the Sea\"", "director"=>"1954-12-23", "genre"=>"RichardFleischer"}
```

Captured the `20` as title with nested quotation marks, and remainder of the title after comma as release date, then date as director, and director as genre, and actual genre was not processed at all.

Need to fix the current code to support quoted columns.

Looking at code again, seems like a lot of work to parse a csv file, is this even code we should be writing? Maybe the Ruby standard library already provides a solution.

It does! [class CSV](https://docs.ruby-lang.org/en/2.7.0/CSV.html)

[read](https://docs.ruby-lang.org/en/2.7.0/CSV.html#method-c-read) method reads in an entire csv file all at once. For our small movies.csv file, this is perfect. It accepts some `options` that are documented in the [new](https://docs.ruby-lang.org/en/2.7.0/CSV.html#method-c-new) method. These options should be provided as a `Hash`.

Option names have colons `:` in front of them - these are *symbols*. For now, think of symbols as minimalistic strings.

Our use of csv is "normal", so the default options for using Ruby's CSV library will work. Notice there is an option for `:headers`, which specifies to use the first row of data as a list of names for the columns that follow. Current code is doing this with `Hash[headers.zip(row)]`.

`:headers_converters` is an option to transform headers into symbols.

Modify code to use the CSV library. We need to `require` it. First simple attempt with no options - looking at first row read in returns the headers:

```ruby
require 'csv'
movies = CSV.read('project_symbols/movies.csv')

p movies.first
# ["title", "release date", "director", "genre"]
```

Now let's try setting the `:headers` option:

```ruby
require 'csv'
movies = CSV.read('project_symbols/movies.csv', :headers => true)

p movies.first
# #<CSV::Row "title":"Star Wars Episode IV: A New Hope" "release date":"1977-05-25" "director":"George Lucas" "genre":"Science Fiction">
```

The `:headers` option has matched up the movie data with the headers. Notice that the headers are strings.

Try `:headers_converters` option to convert headers to symbols:

```ruby
require 'csv'
movies = CSV.read('project_symbols/movies.csv', :headers => true, :header_converters => :symbol)

p movies.first
#<CSV::Row title:"Star Wars Episode IV: A New Hope" release_date:"1977-05-25" director:"George Lucas" genre:"Science Fiction">
```

Now the headers are no longer quoted strings, they've been converted to symbols.

Print 6th movie that happens to be empty line in csv file:

```ruby
require 'csv'
movies = CSV.read('project_symbols/movies.csv', :headers => true, :header_converters => :symbol)

p movies.first
#<CSV::Row title:"Star Wars Episode IV: A New Hope" release_date:"1977-05-25" director:"George Lucas" genre:"Science Fiction">

p movies[5]
#<CSV::Row title:nil release_date:nil director:nil genre:nil>
```

Instructor got `#<CSV::Row>` for empty row, but I get a row of nils. Use `:skip_blanks` option to avoid nil data:

```ruby
require 'csv'
movies = CSV.read('project_symbols/movies.csv', :headers => true, :header_converters => :symbol, :skip_blanks => true)

p movies.first
#<CSV::Row title:"Star Wars Episode IV: A New Hope" release_date:"1977-05-25" director:"George Lucas" genre:"Science Fiction">

p movies[5]
#<CSV::Row title:"Star Wars Episode III: Revenge of the Sith" release_date:"2005-05-19" director:"George Lucas" genre:"Science Fiction">
```

Finally, print out last movie to see how the CSV library handles the quoted movie title. We can no longer use `last` method because `CSV.read` returns array of arrays represented as a `CSV::Table`, which does not have a `last` method:

```ruby
require 'csv'
movies = CSV.read('project_symbols/movies.csv', :headers => true, :header_converters => :symbol, :skip_blanks => true)

p movies[9]
#<CSV::Row title:"20,000 Leagues Under the Sea" release_date:"1954-12-23" director:"RichardFleischer" genre:"Science Fiction">
```

Quoted data was correctly parsed as title.

### Symbols Details