require 'time_pilot'
require 'minitest/spec'
require 'minitest/autorun'

require 'redis'
$redis = Redis.new

class Company
  include TimePilot::Features
  is_pilot_group
  attr_reader :id
  def initialize(id)
    @id = id
  end
end

class Team
  include TimePilot::Features
  is_pilot_group overridden_by: :company
  attr_reader :company_id, :id
  def initialize(company_id, id)
    @company_id = company_id
    @id = id
  end
end

class Employee
  include TimePilot::Features
  is_pilot_group overridden_by: [:company, :team]
  attr_reader :company_id, :team_id, :id
  def initialize(company_id, team_id, id)
    @company_id = company_id
    @team_id = team_id
    @id = id
  end
end

TimePilot.configure do |c|
  c.feature 'planning'
end

describe TimePilot do
  before do
    $redis.flushdb
    @acme = Company.new(1)
    @nedap = Company.new(2)
    @healthcare = Team.new(@nedap.id, 11)
    @retail = Team.new(@nedap.id, 12)
    @john = Employee.new(@nedap.id, @healthcare.id, 21)
    @jane = Employee.new(@nedap.id, @healthcare.id, 22)
  end

  it 'defines a getter on company' do
    $redis.sadd 'timepilot:planning:company_ids', @acme.id
    @acme.planning_enabled?.must_equal true
  end

  it 'defines an enabler on company' do
    @nedap.enable_planning
    $redis.sismember("timepilot:planning:company_ids", @nedap.id).must_equal true
  end

  it 'defines a disabler on employee' do
    @nedap.enable_planning
    @nedap.planning_enabled?.must_equal true
    @nedap.disable_planning
    @nedap.planning_enabled?.must_equal false
  end

  it 'defines a getter on team' do
    $redis.sadd 'timepilot:planning:team_ids', @healthcare.id
    @healthcare.planning_enabled?.must_equal true
  end

  it 'defines an enabler on team' do
    @retail.enable_planning
    $redis.sismember("timepilot:planning:team_ids", @retail.id).must_equal true
  end

  it 'defines a disabler on team' do
    @retail.enable_planning
    @retail.planning_enabled?.must_equal true
    @retail.disable_planning
    @retail.planning_enabled?.must_equal false
  end

  it 'defines a getter on employee' do
    $redis.sadd 'timepilot:planning:employee_ids', @john.id
    @john.planning_enabled?.must_equal true
  end

  it 'defines an enabler on employee' do
    @jane.enable_planning
    $redis.sismember("timepilot:planning:employee_ids", @jane.id).must_equal true
  end

  it 'defines a disabler on employee' do
    @jane.enable_planning
    @jane.planning_enabled?.must_equal true
    @jane.disable_planning
    @jane.planning_enabled?.must_equal false
  end

  specify 'company overrides team' do
    @nedap.enable_planning
    @retail.planning_enabled?.must_equal true
  end

  specify 'team overrides employee' do
    @healthcare.enable_planning
    @john.planning_enabled?.must_equal true
  end

  specify 'company overrides employee' do
    @nedap.enable_planning
    @jane.planning_enabled?.must_equal true
  end
end
