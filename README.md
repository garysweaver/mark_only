# Mark Only

Mark Only is a fork of [Paranoia][paranoia] (by Ryan Bigg and others) with significant changes. It only sets a specified column with a specified value on destroy/delete. Like Paranoia it allows before_destroy, etc. callbacks.

However, it does not unscope marked records. This means that anything that attempts to find the record after a destroy will still find it.

To *really* destroy or delete records, use the Paranoia/acts_as_paranoid convention of calling `destroy!` or `delete!`.

## Installation & Usage

Put this in your Gemfile:

```ruby
gem 'mark_only'
```

Then run:

```shell
bundle install
```

Updating is as simple as `bundle update mark_only`.

#### Run your migrations for the desired models

```ruby
class AddDeletedAtToClient < ActiveRecord::Migration
  def self.up
    add_column :clients, :some_column_to_mark, :string
  end

  def self.down
    remove_column :clients, :some_column_to_mark
  end
end
```

### Usage

#### In your environment.rb:

```ruby
MarkOnly.configure do
  self.active_value = 'active'
  self.deleted_value = 'deleted'
end

...
```

#### In your model:

```ruby
class Client < ActiveRecord::Base
  mark_only :some_column_to_mark

  ...
end
```

If you want a method to be called on destroy, simply provide a _before\_destroy_ callback:

```ruby
class Client < ActiveRecord::Base
  mark_only :some_column_to_mark

  before_destroy :some_method

  def some_method
    # do stuff
  end

  ...
end
```

## License

This gem is released under the MIT license.

[paranoia]: https://github.com/radar/paranoia
