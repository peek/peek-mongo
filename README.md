# Peek::Mongo

Take a peek into the Mongo commands made within your Rails application.

Things this peek view provides:

- Total number of Mongo commands called during the request
- The duration of the calls made during the request

## Installation

Add this line to your application's Gemfile:

    gem 'peek-mongo'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install peek-mongo

## Usage

Add the following to your `config/initializers/peek.rb`: 

```ruby
Peek.into Peek::Views::Mongo
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
