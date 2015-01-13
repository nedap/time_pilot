# TimePilot [![Build Status](https://travis-ci.org/nedap/time_pilot.svg)](https://travis-ci.org/nedap/time_pilot) ![Code Climate](https://codeclimate.com/repos/538c225ae30ba00d55006394/badges/1741b217ec9818699a37/gpa.png)

TimePilot is a RubyGem that makes it possible to define features that can be enabled for a certain group of users. It requires very little configuration, and is designed to work stand-alone on any object. TimePilot uses Redis for storage.

## Installation

Add this line to your application's Gemfile:

    gem 'time_pilot'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install time_pilot

# Configuration

The features that you want to specify need to be added in an initializer as such:

```ruby
# config/initializers/time_pilot.rb
TimePilot.configure do |c|
  c.feature :planning
  c.feature :private_messaging
end
```

Using this configuration, the `TimePilot::Features` module is enriched with three methods per feature at boot time: `{feature}_enabled?`, `enable_{feature}` and `disable_{feature}`. In every model that you would want to invoke these methods, i.e. check if a feature is enabled or either enable or disable it for that group you need to `include TimePilot::Features`.

After including `TimePilot::Features` add: `is_pilot_group`. You can specify an `overridden_by: [:foo, :bar, ...]` to specify any relations that override the setting for the object itself. See the example below for `Team` and `User`.

```ruby
# app/model/organization.rb
class Organization
  attr_accessor :id

  include TimePilot::Features
  is_pilot_group
end

# app/model/team.rb
class Team
  attr_accessor :organization_id, :id

  include TimePilot::Features
  is_pilot_group overridden_by: :organization
end

# app/model/user.rb
class User
  attr_accessor :organization_id, :team_id, :id

  include TimePilot::Features
  is_pilot_group overridden_by: [:organization, :team]
end

# app/model/person.rb
class Person
  attr_accessor :id

  include TimePilot::Features
  is_pilot_group
end
```

When you invoke `user.planning_enabled?`, TimePilot fill first check if the feature has been enabled for the organization with the ID obtained from `user.organization_id`. If that evaluates to `false`, TimePilot continues checking the feature, but now using `user.team_id`. Then, if that fails too, it checks whether the feature is enabled for the user itself.

## Configuring Redis

TimePilot uses `localhost:6379` by default for Redis. To connect to a Redis instance on a different port or host, provide a Redis client in `TimePilot.configure` block.

```
# config/initializers/time_pilot.rb
TimePilot.configure do |c|
  c.redis Redis.new(...)
end
```

## Multiple configure blocks

TimePilot allows you to specify more than one configure block. This allows you to specify features at multiple levels. For example, you could specify features in a Rails Engine located in a separate gem, as well as the host application. It's easy as this:

```ruby
# vendor/gems/.../config/initializers/time_pilot.rb
TimePilot.configure do |c|
  c.feature :this_could_be_my_rails_engine
end

# config/initializers/time_pilot.rb
TimePilot.configure do |c|
  c.feature :this_is_my_host_application
end
```

TimePilot assumes you put in an object that responds to `#sadd`, `#srem` and `#sismember`.

# Usage

The configuration above allows you to invoke the following methods on a `Organization`, `Team`, `User` and `Person`:

```ruby
# Methods for feature 'planning'
user.planning_enabled?
user.enable_planning
user.disable_planning

# Methods for feature 'private_messaging'
user.private_messaging_enabled?
user.enable_private_messaging
user.disable_private_messaging

# The same methods can be invoked on an instance of Organization,
# Team and Person provided the example above, since they all include
# the `Features` module.
```
