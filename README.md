# Idiomatic Ruby

My notes from Pluralsight [course](https://app.pluralsight.com/library/courses/ruby-idiomatic/table-of-contents).

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

TBD...