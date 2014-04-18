# TimePilot

# Configuration

```ruby
TimePilot.configure do |c|
  c.feature :planning
  c.feature :private_messaging
end
```

```ruby
class User
  attr_reader :organization_id, :team_id

  include TimePilot::Features
  is_pilot_group overridden_by: [:organization, :team]
end
```

This allows you to invoke the following methods on a `User`:

```ruby
# Methods for feature 'planning'
user.planning_enabled?
user.enable_planning
user.disable_planning

# Methods for feature 'private_messaging'
user.private_messaging_enabled?
user.enable_private_messaging
user.disable_private_messaging
```
