require_relative '../lib/time_pilot'
require 'minitest/autorun'

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

TimePilot.configure do |c|
  c.feature 'secret_feature'
end

describe TimePilot do
  before do
    TimePilot.redis.flushdb
    @acme = Company.new(1)
    @nedap = Company.new(2)
    @healthcare = Team.new(@nedap.id, 11)
    @retail = Team.new(@nedap.id, 12)
    @john = Employee.new(@nedap.id, @healthcare.id, 21)
    @jane = Employee.new(@nedap.id, @healthcare.id, 22)
  end

  it 'allows multiple configure blocks to add features' do
    TimePilot.features.must_equal ['planning', 'secret_feature']
    @acme.planning_enabled?.must_equal false
    @acme.secret_feature_enabled?.must_equal false
  end

  it 'defines a getter on company' do
    TimePilot.redis.sadd 'timepilot:planning:company_ids', @acme.id
    @acme.planning_enabled?.must_equal true
    @acme.planning_enabled.must_equal true
  end

  it 'defines an enabler on company' do
    @nedap.enable_planning
    TimePilot.redis.sismember("timepilot:planning:company_ids", @nedap.id).must_equal true
  end

  it 'defines a disabler on employee' do
    @nedap.enable_planning
    @nedap.planning_enabled?.must_equal true
    @nedap.planning_enabled.must_equal true
    @nedap.disable_planning
    @nedap.planning_enabled?.must_equal false
    @nedap.planning_enabled.must_equal false
  end

  it 'defines a getter on team' do
    TimePilot.redis.sadd 'timepilot:planning:team_ids', @healthcare.id
    @healthcare.planning_enabled?.must_equal true
  end

  it 'defines an enabler on team' do
    @retail.enable_planning
    TimePilot.redis.sismember("timepilot:planning:team_ids", @retail.id).must_equal true
  end

  it 'defines a disabler on team' do
    @retail.enable_planning
    @retail.planning_enabled?.must_equal true
    @retail.planning_enabled.must_equal true
    @retail.disable_planning
    @retail.planning_enabled?.must_equal false
    @retail.planning_enabled.must_equal false
  end

  it 'defines a getter on employee' do
    TimePilot.redis.sadd 'timepilot:planning:employee_ids', @john.id
    @john.planning_enabled?.must_equal true
    @john.planning_enabled.must_equal true
  end

  it 'defines an enabler on employee' do
    @jane.enable_planning
    TimePilot.redis.sismember("timepilot:planning:employee_ids", @jane.id).must_equal true
  end

  it 'defines a disabler on employee' do
    @jane.enable_planning
    @jane.planning_enabled?.must_equal true
    @jane.planning_enabled.must_equal true
    @jane.disable_planning
    @jane.planning_enabled?.must_equal false
    @jane.planning_enabled.must_equal false
  end

  it 'defines a cardinality count on the classes' do
    @nedap.enable_planning
    @john.enable_planning
    @jane.enable_planning
    Company.pilot_feature_cardinality(:planning).must_equal 1
    Team.pilot_feature_cardinality(:planning).must_equal 0
    Employee.pilot_feature_cardinality(:planning).must_equal 2
  end

  it 'registers classes that include TimePilot::Features' do
    TimePilot.group_classes.must_include Company
    TimePilot.group_classes.must_include Team
    TimePilot.group_classes.must_include Employee
  end

  specify 'company overrides team' do
    @nedap.enable_planning
    @retail.planning_enabled?.must_equal true
    @retail.planning_enabled.must_equal true
  end

  specify 'team overrides employee' do
    @healthcare.enable_planning
    @john.planning_enabled?.must_equal true
    @john.planning_enabled.must_equal true
  end

  specify 'company overrides employee' do
    @nedap.enable_planning
    @jane.planning_enabled?.must_equal true
    @jane.planning_enabled.must_equal true
  end
end

class CamelCasedModel
  include TimePilot::Features
  is_pilot_group
end

describe TimePilot, 'converting CamelCase to camel_case' do
  it do
    CamelCasedModel.time_pilot_groups.must_equal ['camel_cased_model']
  end
end

describe TimePilot, 'reduce redis load' do
  it 'calls redis only once' do
    TimePilot.redis.expect(:sismember, true, ['timepilot:planning:company_ids', @acme.id])

    @acme.planning_enabled?.must_equal true
    @acme.planning_enabled?.must_equal true
  end
end
