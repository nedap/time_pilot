# TimePilot [![Testing](https://github.com/nedap/time_pilot/actions/workflows/ruby.yml/badge.svg)](https://github.com/nedap/time_pilot/actions/workflows/ruby.yml) ![Code Climate](https://codeclimate.com/repos/538c225ae30ba00d55006394/badges/1741b217ec9818699a37/gpa.png)

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

TimePilot assumes you put in an object that responds to `#sadd`, `#srem`, `#sismember` and `#scard`.

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

## TimePilot Web

TimePilot provides a dashboard that is mountable inside a Rails app.
```ruby
# in config/initializers/time_pilot.rb
require 'time_pilot/web'
TimePilot::Web.use(Rack::Auth::Basic) do |user, password|
  username == ENV["TIME_PILOT_USERNAME"] && password == ENV["TIME_PILOT_PASSWORD"]
end

# in routes.rb
Application.routes.draw do
  mount TimePilot::Web => '/time_pilot'
end
```

`TimePilot::Web` is just a Rack app. You can use it outside Rails.

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

# Publish

The following steps are needed to publish time_pilot:

* Bump version in `version.rb`
* Commit new version with:

  ```
  git commit --message "Bump to version $VERSION"
  ```
* Tag the new version:

  ```
  git tag $VERSION
  ```
* Push the bump commit and tag:

  ```
  git push --tags
  ```
* Build the gem:

  ```
  gem build time_pilot.gemspec
  ```
* Push to gemfury:

  ```
  fury push time_pilot-${VERSION}.gem --as=nedap-healthcare
  ```
* Push to Rubygems:

  ```
  gem push time_pilot-${VERSION}.gem
  ```
