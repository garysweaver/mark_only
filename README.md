[![Build Status](https://secure.travis-ci.org/FineLinePrototyping/mark_only.png?branch=master)][travis] [![Gem Version](https://badge.fury.io/rb/mark_only.png)][badgefury]

# Mark Only

Want to only mark a column with a value when the record is deleted or destroyed, but not unscope it? Then you're in the right place. If you want the records to be out of scope, look at acts_as_paranoid, paranoid, etc.

`mark_only` on the model class sets a specified column with a specified value on destroy/delete and disables the ability to `delete`/`destroy` on instance, model class, and via relation, using the default ActiveRecord version of those, and supports destroy callbacks if raise not enabled. `destroy!` in Rails 4 is supported.

Once a record is marked, `deleted?`/`destroyed?` methods on a retrieved model instance return false.

Tested with ActiveRecord 4.1.x, 4.2.x via travis and appraisal.

Code originally based on [Paranoia][paranoia] (by Ryan Bigg and others), but heavily modified.

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
    add_column :clients, :some_column_to_mark, :string, :default => 'active'
  end

  def self.down
    remove_column :clients, :some_column_to_mark
  end
end
```

Use the active_value as `:default`.

### Usage

#### In your environment.rb:

```ruby
MarkOnly.configure do
  # if true, debug log failed attempts to delete/destroy
  self.debug = false
  # the value that should indicate that a record is deleted
  self.deleted_value = 'deleted'
  # only needed if you use scopes:
  self.active_scope_name = 'active'
  self.deleted_scope_name = 'deleted'
end

...
```

#### In your model:

To disallow attempts to delete/destroy and instead update the specified column:

```ruby
class Client < ActiveRecord::Base
  mark_only :some_column_to_mark

  ...
end
```

To also add scopes to filter by the marked column value, use the scopes option:

```ruby
class Client < ActiveRecord::Base
  mark_only :some_column_to_mark, scopes: true

  ...
end
```

#### Disabling Globally

If you need to globally disable temporarily so that everything marked as mark_only will destroy/delete instead of work normally, which might be useful in a data cleanup script, use:

```ruby
MarkOnly.enabled = false
```

Note: that is an application-wide setting affecting all models that use mark_only, and may allow destruction of data you did not intend to destroy. Please be careful!

## Upgrading

* v0.0.1 -> v1.0.x: `restore!` no longer supported; the workaround is to use SQL to change a record's mark column to some value other than MarkOnly.deleted_value. Similarly, if you need to really delete or destroy a row in the database corresponding to the record, use SQL.

## License

This gem is released under the [MIT license][lic].

[lic]: http://github.com/FineLinePrototyping/mark_only/blob/master/LICENSE
[paranoia]: https://github.com/radar/paranoia
[travis]: http://travis-ci.org/FineLinePrototyping/mark_only
[badgefury]: http://badge.fury.io/rb/mark_only
