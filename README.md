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
      - [Strings](#strings)
      - [Symbols](#symbols)
    - [Summary](#summary)
      - [Pro Tip](#pro-tip)
  - [Building Objects](#building-objects)
    - [Desired Behavior](#desired-behavior)
    - [Unit Testing: Why and How](#unit-testing-why-and-how)
    - [First Unit Test: attr_reader](#first-unit-test-attr_reader)
    - [Our Second Unit Test: attr_writer](#our-second-unit-test-attr_writer)
  - [Enumerable is our Pal](#enumerable-is-our-pal)
    - [Map: Transforming Collections](#map-transforming-collections)

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

For some use cases, prefer symbols over strings.

#### Strings

Strings are mutable objects:

```ruby
# can be added together
str = "ruby" + " is"

# can modify contents with methods
str.upcase!

# can use shovel operator (modifies contents of str string)
puts str << " awesome!"
# => RUBY IS awesome!
```

Above code has created 4 string objects in memory:

1. "str"
2. " is"
3. "ruby is" (concatenation of previous two strings)
4. " awesome!"

Two compare two strings, Ruby must do this character by character.

If want to use a string as a hash key, Ruby must generate the hash code character by character.


#### Symbols

Symbols are simpler than strings. Cannot be added together or changed in any way:

```ruby
:ruby + :awesome
# => NoMethodError
```

Ruby can check if two symbols are equal, generating their hash codes, much faster than strings:

```ruby
:ruby == :ruby # => true
```

No matter how many times you write the same symbol in a program, Ruby only creates a single object in memory for it:

```ruby
:ruby.object_id # => 323688
:ruby.object_id # => 323688
```

Symbols function as enums from other programming languages.

Ruby keeps track of all the symbols it has seen in a program.

Code can treat symbols as integers when checking for equality or generating hash codes.

As of Ruby 1.9, symbols can also be specified by putting colon at the end, and don't need the equals arrow. This looks similar to JSON declaration:

```ruby
{
  integer: 1,
  float: 0.5,
  string: "ohai",
  object: Object.new
}
```

### Summary

Idioms covered in this section:

* Blocks
* Conditionals
* Symbols

Often most commonly used Ruby libraries (aka gems) from community get merged into Ruby standard library. eg: CSV library used in this project was originally a gem faster csv.

#### Pro Tip

If it has a name, it probably has a library to solve the problem you're trying to code:

* [Standard Library](https://ruby-doc.org/)
* [Gem](https://rubygems.org/)

You're usually better off using a library than re-writing that solution in your project. eg: CSV one-liner in our movies parsing code is way easier to read than original version we started with.

## Building Objects

Everything is an object including numbers, classes, methods.

### Desired Behavior

Recall movies project so far, just parsing csv:

```ruby
require 'csv'
movies = CSV.read('project_symbols/movies.csv', :headers => true, :header_converters => :symbol, :skip_blanks => true)
```

Now [movies.csv](project_object/movies.csv) has more rows, *and* a new column `rotten tomatoes` with percentage score.

Print out one of the parsed rows to see what kind of object is it:

```ruby
require 'csv'
movies = CSV.read('project_symbols/movies.csv', :headers => true, :header_converters => :symbol, :skip_blanks => true)

p movies[9]
# #<CSV::Row title:"20,000 Leagues Under the Sea" release_date:"1954-12-23" director:"Richard Fleischer" genre:"Science Fiction" rotten_tomatoes:"89">
```

It's a `CSV::Row` object, generated by the `CSV` library.

Try to query this object for the `title` attribute:

```ruby
...
p movies[9].title
# undefined method `title' for #<CSV::Row:0x00007f93c20f9f08> (NoMethodError)
```

The csv row object contains parsed data from the csv file, but doesn't have context or understand what this data means, that's why it doesn't respond to a `title` method.

However, the data can be accessed with hash syntax and a symbol as key, which is not as natural as calling `.title`:

```ruby
p movies[9][:title]
# "20,000 Leagues Under the Sea"
```

Another issue is accessing the date returns a string rather than an actual date:

```ruby
p movies[9][:release_date]
# "1954-12-23"
```

The CSV library doesn't know what the data represents, so it hasn't converted it.

We need conversion to date to perform analysis such as:
* Is there any correlation between movies with highest ratings and release month
* Are all my favorite movies from the same decade?

Can't ask a string date what month it occurs in:

```ruby
p movies[9][:release_date].year
# undefined method `year' for "1954-12-23":String (NoMethodError)
```

Need the `release_date` data parsed into a date Object rather than a String.

Same problem with `rotten_tomatoes` score, its a String rather than Integer, which would be needed to perform calculations such as average:

```ruby
p movies[9][:rotten_tomatoes]
# "89"

p movies[9][:rotten_tomatoes] / 100
# undefined method `/' for "89":String (NoMethodError)
```

What's needed to solve these problems is to generate a list of `movie` objects such as:

```ruby
movie.title # => "Star Wars..."
movie.director # => "George..."
movie.gengre # => "Science..."
movie.release_date # => Date.new(1977,5,25)
movie.rotten_tomatoes # => 93
```

In a situation where you know the input (eg: movies.csv data) and you know exactly what you want (eg: a list of movie objects as described above), start with unit tests.

### Unit Testing: Why and How

Defining object behaviour. Options:

* MiniTest: Simple, Standard Library (can use in any project without loading a gem)
* RSpec: Readability, gem

MiniTest example, the test class inherits from class `MiniTest::Test`:

```ruby
class FizzBuzzTest < MiniTest::Test
  def setup
    # object under test
    @fizz_buss = FizzBuzz.new
  end

  def test_three
    assert_equal "1, 2, Fizz", @fiZZ_buzz.talk(3)
  end

  def test_five
    assert_equal "1, 2, Fizz, 4, Buzz", @fiZZ_buzz.talk(5)
  end
end
```

When the tests are run, MiniTest looks for all classes that inherit from `MiniTest::Test`, finds all methods in these classes that start with `test_...` and runs each as a test.

RSpec example:

```ruby
describe FizzBuzzz do
  it "replaces divisors of 3 with Fizz" do
    expect(subject.talk(3)).to eq "1, 2, Fizz"
  end

  it "replaces divisors of 5 with Fizz" do
    expect(subject.talk(5)).to eq "1, 2, Fizz, 4, Buzz"
  end
end
```

Notice there's no explicit class defined. Use `describe` with a block. Keeps focus on expected behaviour rather than defining new code.

Rather than defining test methods, use `it` blocks.

`describe FizzBuzz` tells RSpec that class `FizzBuzz` is being tested, so it creates a default `subject` object by calling `FizzBuzz.new` behind the scenes.

For this course will use MiniTest because it ships with Ruby. But it's good to know both because they're both widely used.

### First Unit Test: attr_reader

Will use TDD approach.

[movie.rb](unit_test/movie.rb) | [movie_test.rb](unit_test/movie_test.rb)

In the test `setup` method, initialize a movie object with a hash. In actual fact it will get initialized from a csv row object, but this is similar to a hash.

Simplest possible test of the movie object is to ask for its director, and ensure it returns "George Lucas":

```ruby
# require test framework
require 'minitest/autorun'

# require class under test
require_relative 'movie'

# inherit from test framework
class MovieTest < MiniTest::Test
  def setup
    # initialize test object with a hash
    @movie = Movie.new({
      :title => "Star Wars",
      :genre => "Science Fiction",
      :director => "George Lucas",
      :release_date => "1977-05-25",
      :rotten_tomatoes => "93"
    })
  end

  def test_director
    assert_equal "George Lucas", @movie.director
  end
end
```

Running the test file `ruby /path/to/test_file.rb` or using VS Code runner, and this test fails:

```
[Running] ruby "/Users/dbaron/projects/pluralsight/idiomatic-ruby-pluralsight/unit_test/movie_test.rb"
Run options: --seed 61979

# Running:

E

Error:
MovieTest#test_director:
ArgumentError: wrong number of arguments (given 1, expected 0)
    /Users/dbaron/projects/pluralsight/idiomatic-ruby-pluralsight/unit_test/movie_test.rb:6:in `initialize'
    /Users/dbaron/projects/pluralsight/idiomatic-ruby-pluralsight/unit_test/movie_test.rb:6:in `new'
    /Users/dbaron/projects/pluralsight/idiomatic-ruby-pluralsight/unit_test/movie_test.rb:6:in `setup'

rails test Users/dbaron/projects/pluralsight/idiomatic-ruby-pluralsight/unit_test/movie_test.rb:15



Finished in 0.001044s, 957.8544 runs/s, 0.0000 assertions/s.
1 runs, 0 assertions, 0 failures, 1 errors, 0 skips

[Done] exited with code=1 in 0.703 seconds
```

Error is on trying to construct the movie object. Ruby's default constructor takes no arguments, but test code is passing a single argument (hash) to the `Movie` class constructor.

To fix this, go to Movie class and define `initialize` method to make this part of the test pass. Initializer should accept a csv row, extract the director variable, and save it to `@director` instance variable, then define a method that simply returns this instance variable:

```ruby
class Movie
  def initialize(csv_row)
    @director = csv_row[:director]
  end

  def director
    return @director
  end
end
```

Run the test again and this time it passes:

```
[Running] ruby "/Users/dbaron/projects/pluralsight/idiomatic-ruby-pluralsight/unit_test/movie_test.rb"
Run options: --seed 10834

# Running:

.

Finished in 0.001272s, 786.1635 runs/s, 786.1635 assertions/s.
1 runs, 1 assertions, 0 failures, 0 errors, 0 skips

[Done] exited with code=0 in 0.511 seconds
```

Let's add similar tests to access the remaining movie attributes. Notice that the release date test expects to receive a Date object, and the rotten tomatoes test expects to get a Number object.

```ruby
require 'minitest/autorun'
require_relative 'movie'

# instructor did not do so but I had to require date library as per docs at:
# https://docs.ruby-lang.org/en/2.7.0/Date.html
require 'date'

class MovieTest < MiniTest::Test
  def setup
    @movie = Movie.new({
      :title => "Star Wars",
      :genre => "Science Fiction",
      :director => "George Lucas",
      :release_date => "1977-05-25",
      :rotten_tomatoes => "93"
    })
  end

  def test_director
    assert_equal "George Lucas", @movie.director
  end

  def test_genre
    assert_equal "Science Fiction", @movie.genre
  end

  def test_release_date
    assert_equal Date.new(1977,5,25), @movie.release_date
  end

  def test_rotten_tomatoes
    assert_equal 93, @movie.rotten_tomatoes
  end

  def test_title
    assert_equal "Star Wars", @movie.title
  end
end
```

Running the test now will generate a lot of errors because we haven't yet defined methods for the other attributes (other than director):

```
[Running] ruby "/Users/dbaron/projects/pluralsight/idiomatic-ruby-pluralsight/unit_test/movie_test.rb"
Run options: --seed 46587

# Running:

.E

Error:
MovieTest#test_release_date:
NoMethodError: undefined method `release_date' for #<Movie:0x00007fde36133988 @director="George Lucas">
    /Users/dbaron/projects/pluralsight/idiomatic-ruby-pluralsight/unit_test/movie_test.rb:25:in `test_release_date'

rails test Users/dbaron/projects/pluralsight/idiomatic-ruby-pluralsight/unit_test/movie_test.rb:24

E

Error:
MovieTest#test_genre:
NoMethodError: undefined method `genre' for #<Movie:0x00007fde36128d30 @director="George Lucas">
    /Users/dbaron/projects/pluralsight/idiomatic-ruby-pluralsight/unit_test/movie_test.rb:21:in `test_genre'

rails test Users/dbaron/projects/pluralsight/idiomatic-ruby-pluralsight/unit_test/movie_test.rb:20

E

Error:
MovieTest#test_rotten_tomatoes:
NoMethodError: undefined method `rotten_tomatoes' for #<Movie:0x00007fde36118778 @director="George Lucas">
    /Users/dbaron/projects/pluralsight/idiomatic-ruby-pluralsight/unit_test/movie_test.rb:29:in `test_rotten_tomatoes'

rails test Users/dbaron/projects/pluralsight/idiomatic-ruby-pluralsight/unit_test/movie_test.rb:28

E

Error:
MovieTest#test_title:
NoMethodError: undefined method `title' for #<Movie:0x00007fde36108f80 @director="George Lucas">
    /Users/dbaron/projects/pluralsight/idiomatic-ruby-pluralsight/unit_test/movie_test.rb:33:in `test_title'

rails test Users/dbaron/projects/pluralsight/idiomatic-ruby-pluralsight/unit_test/movie_test.rb:32



Finished in 0.007696s, 649.6881 runs/s, 129.9376 assertions/s.
5 runs, 1 assertions, 0 failures, 4 errors, 0 skips

[Done] exited with code=1 in 0.422 seconds
```

Go back to Movie class to fix this. Need to capture all data from csv_row as instance variables in initializer, then define methods to return these instance variables:

```ruby
class Movie
  def initialize(csv_row)
    @director = csv_row[:director]
    @genre = csv_row[:genre]
    @release_date = csv_row[:release_date]
    @rotten_tomatoes = csv_row[:rotten_tomatoes]
    @title = csv_row[:title]
  end

  def director
    return @director
  end

  def genre
    return @genre
  end

  def release_date
    return @release_date
  end

  def rotten_tomatoes
    return @rotten_tomatoes
  end

  def title
    return @title
  end
end
```

Running the test again leaves a couple errors - for rotten tomatoes and release date due to data types. `csv_row` object contains all strings but test expects the Movie class to have converted these to number and date respectively:

```
[Running] ruby "/Users/dbaron/projects/pluralsight/idiomatic-ruby-pluralsight/unit_test/movie_test.rb"
Run options: --seed 14439

# Running:

..F

Failure:
MovieTest#test_release_date [/Users/dbaron/projects/pluralsight/idiomatic-ruby-pluralsight/unit_test/movie_test.rb:25]:
--- expected
+++ actual
@@ -1 +1 @@
-#<Date: 1977-05-25 ((2443289j,0s,0n),+0s,2299161j)>
+"1977-05-25"


rails test Users/dbaron/projects/pluralsight/idiomatic-ruby-pluralsight/unit_test/movie_test.rb:24

F

Failure:
MovieTest#test_rotten_tomatoes [/Users/dbaron/projects/pluralsight/idiomatic-ruby-pluralsight/unit_test/movie_test.rb:29]:
Expected: 93
  Actual: "93"

rails test Users/dbaron/projects/pluralsight/idiomatic-ruby-pluralsight/unit_test/movie_test.rb:28

.

Finished in 0.030183s, 165.6562 runs/s, 165.6562 assertions/s.
5 runs, 5 assertions, 2 failures, 0 errors, 0 skips

[Done] exited with code=1 in 0.576 seconds
```

To fix the date issue, require the date library in Movie class, and use `Date.parse` method when initializing the release_date instance variable:

```ruby
require 'date'

class Movie
  def initialize(csv_row)
    @director = csv_row[:director]
    @genre = csv_row[:genre]
    @release_date = Date.parse(csv_row[:release_date])
    @rotten_tomatoes = csv_row[:rotten_tomatoes]
    @title = csv_row[:title]
  end
  # ...
end
```

Now test runs with only rotten tomatoes error re: number type:

```
[Running] ruby "/Users/dbaron/projects/pluralsight/idiomatic-ruby-pluralsight/unit_test/movie_test.rb"
Run options: --seed 57612

# Running:

....F

Failure:
MovieTest#test_rotten_tomatoes [/Users/dbaron/projects/pluralsight/idiomatic-ruby-pluralsight/unit_test/movie_test.rb:29]:
Expected: 93
  Actual: "93"

rails test Users/dbaron/projects/pluralsight/idiomatic-ruby-pluralsight/unit_test/movie_test.rb:28



Finished in 0.001611s, 3103.6623 runs/s, 3103.6623 assertions/s.
5 runs, 5 assertions, 1 failures, 0 errors, 0 skips

[Done] exited with code=1 in 0.549 seconds
```

To fix this, invoke the `to_i` method on the string returned from csv row, in the Movie class initializer:

```ruby
require 'date'

class Movie
  def initialize(csv_row)
    @director = csv_row[:director]
    @genre = csv_row[:genre]
    @release_date = Date.parse(csv_row[:release_date])
    @rotten_tomatoes = csv_row[:rotten_tomatoes].to_i
    @title = csv_row[:title]
  end
  # ...
end
```

Now all tests pass:

```
[Running] ruby "/Users/dbaron/projects/pluralsight/idiomatic-ruby-pluralsight/unit_test/movie_test.rb"
Run options: --seed 37075

# Running:

.....

Finished in 0.001498s, 3337.7837 runs/s, 3337.7837 assertions/s.
5 runs, 5 assertions, 0 failures, 0 errors, 0 skips

[Done] exited with code=0 in 0.417 seconds
```

We now have movie object that behaves as expected. But we had to write a lot of code in Movie class to achieve this. It's tme to refactor Movie class to make it simpler. The automated tests we wrote will ensure we're not breaking things as we refactor.

First thing to note is all the getter methods are essentially the same, they return the instance variable of the same name as the getter method.

In Ruby, the last value in a given expression is always the return value of that expression. So we can eliminate all the `return`s. Only need to use `return` when want to explicitly exit a method early:

```ruby
require 'date'

class Movie
  def initialize(csv_row)
    @director = csv_row[:director]
    @genre = csv_row[:genre]
    @release_date = Date.parse(csv_row[:release_date])
    @rotten_tomatoes = csv_row[:rotten_tomatoes].to_i
    @title = csv_row[:title]
  end

  def director
    @director
  end

  def genre
    @genre
  end

  def release_date
    @release_date
  end

  def rotten_tomatoes
    @rotten_tomatoes
  end

  def title
    @title
  end
end
```

Run the tests again - all pass.

Next improvement - defining getter methods is a common pattern, so Ruby provides a built-in macro: `attr_reader`. To use it, remove all getter methods, and invoke `attr_reader` macro at top of class with list of all attributes. This macro defines getter methods for all the attributes given to it:

```ruby
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
```

All the tests still pass.

### Our Second Unit Test: attr_writer

[movie.rb](second_unit_test/movie.rb) | [movie_test.rb](second_unit_test/movie_test.rb)

We'd like our movie object to have some predicate methods so we can answer questions such as "is this movie a comedy"?. Start by defining this behaviour in the test:

```ruby
require 'minitest/autorun'
require_relative 'movie'
require 'date'

class MovieTest < MiniTest::Test
  def setup
    @movie = Movie.new({
      :title => "Star Wars",
      :genre => "Science Fiction",
      :director => "George Lucas",
      :release_date => "1977-05-25",
      :rotten_tomatoes => "93"
    })
  end

  def test_comedy?
    assert_equal false, @movie.comedy?
  end

  # ...
end
```

But to test completely, need both a test where `comedy?` returns false, and one where it returns true. Update the test to change movie genre, then assert again:

```ruby
def test_comedy?
  assert_equal false, @movie.comedy?
  @movie.genre = "Comedy"
  assert_equal true, @movie.comedy?
end
```

Run tests now, expect the new test to fail because `comedy?` predicate method not yet implemented:

```
Error:
MovieTest#test_comedy?:
NoMethodError: undefined method `comedy?' for #<Movie:0x00007f9a4c0b24b0>
    /Users/dbaron/projects/pluralsight/idiomatic-ruby-pluralsight/second_unit_test/movie_test.rb:17:in `test_comedy?'

rails test Users/dbaron/projects/pluralsight/idiomatic-ruby-pluralsight/second_unit_test/movie_test.rb:16

....

Finished in 0.002414s, 2485.5012 runs/s, 2071.2510 assertions/s.
6 runs, 5 assertions, 0 failures, 1 errors, 0 skips
```

To fix this, implement the missing method in the movie class by simply checking if the genre attribute is "Comedy":

```ruby
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

  def comedy?
    genre == "Comedy"
  end
end
```

Now running tests get a different failure, that there's no method defined for `genre=`. It comes from the line in the test that's trying to write a new genre value to the movie object, but the object currently does not support writing to its attribute:

```ruby
@movie.genre = "Comedy"
```

To fix this, add a setter method to movie class for genre:

```ruby
class Movie
  # ...

  def genre=(new_genre)
    @genre = new_genre
  end

  # ...
end
```

Now the tests pass.

Now time to refactor - just like manually writing getter methods can be replaced with the `attr_reader` macro, manually writing setter methods can be replaced with the `attr_writer` macro. This macro defines setter methods for all the given attributes:

```ruby
require 'date'

class Movie
  attr_reader :director, :genre, :release_date, :rotten_tomatoes, :title
  attr_writer :genre

  def initialize(csv_row)
    @director = csv_row[:director]
    @genre = csv_row[:genre]
    @release_date = Date.parse(csv_row[:release_date])
    @rotten_tomatoes = csv_row[:rotten_tomatoes].to_i
    @title = csv_row[:title]
  end

  def comedy?
    genre == "Comedy"
  end
end
```

Run the tests again - all passing.

Look at movie class again and ask "can we do better?". Notice that `:genre` is an argument to both `attr_reader` and `attr_writer` macros. This can be replaced with the `attr_accessor` macro that generates *both* getter and setter methods for the given attributes:

```ruby
require 'date'

class Movie
  attr_accessor :genre
  attr_reader :director, :release_date, :rotten_tomatoes, :title

  def initialize(csv_row)
    @director = csv_row[:director]
    @genre = csv_row[:genre]
    @release_date = Date.parse(csv_row[:release_date])
    @rotten_tomatoes = csv_row[:rotten_tomatoes].to_i
    @title = csv_row[:title]
  end

  def comedy?
    genre == "Comedy"
  end
end
```

Run the tests again - all passing.

Modify movie class to make all attributes readable and writable:

```ruby
require 'date'

class Movie
  attr_accessor :director, :genre, :release_date, :rotten_tomatoes, :title

  def initialize(csv_row)
    @director = csv_row[:director]
    @genre = csv_row[:genre]
    @release_date = Date.parse(csv_row[:release_date])
    @rotten_tomatoes = csv_row[:rotten_tomatoes].to_i
    @title = csv_row[:title]
  end

  def comedy?
    genre == "Comedy"
  end
end
```

All tests still passing.

Conclusion: Now have a Movie object to make it easier to interact with movie library.

## Enumerable is our Pal

### Map: Transforming Collections