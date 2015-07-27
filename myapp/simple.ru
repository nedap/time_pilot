require 'time_pilot'

TimePilot.configure do |c|
  c.feature :planning
  c.feature :private_messaging
end

class Team
  attr_accessor :id
  include TimePilot::Features
  is_pilot_group
end

class Employee
  attr_accessor :id, :team_id
  include TimePilot::Features
  is_pilot_group overridden_by: [:team]
end

healthcare = Team.new
healthcare.id = 1
healthcare.enable_planning

john = Employee.new
john.id = 1
john.team_id = healthcare.id
john.enable_planning
john.enable_private_messaging

jane = Employee.new
jane.id = 2
jane.team_id = healthcare.id
jane.enable_planning
jane.disable_planning
jane.enable_private_messaging

require 'time_pilot/web'
TimePilot::Web.use(Rack::Auth::Basic) do
  true
end

run TimePilot::Web
