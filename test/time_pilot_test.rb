# frozen_string_literal: true

require_relative "../lib/time_pilot"
require "minitest/autorun"

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
  is_pilot_group overridden_by: %i[company team]
  attr_reader :company_id, :team_id, :id

  def initialize(company_id, team_id, id)
    @company_id = company_id
    @team_id = team_id
    @id = id
  end
end

TimePilot.configure do |c|
  c.feature "planning"
end

TimePilot.configure do |c|
  c.feature "secret_feature"
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

  it "allows multiple configure blocks to add features" do
    _(TimePilot.features).must_equal %w[planning secret_feature]
    _(@acme.planning_enabled?).must_equal false
    _(@acme.secret_feature_enabled?).must_equal false
  end

  it "defines a getter on company" do
    TimePilot.redis.sadd "timepilot:planning:company_ids", @acme.id
    _(@acme.planning_enabled?).must_equal true
    _(@acme.instance_variable_get("@planning_enabled")).must_equal true
  end

  it "defines an enabler on company" do
    @nedap.enable_planning
    _(TimePilot.redis.sismember("timepilot:planning:company_ids", @nedap.id)).must_equal true
  end

  it "defines a disabler on employee" do
    @nedap.enable_planning
    _(@nedap.planning_enabled?).must_equal true
    _(@nedap.instance_variable_get("@planning_enabled")).must_equal true
    @nedap.disable_planning
    _(@nedap.planning_enabled?).must_equal false
    _(@nedap.instance_variable_get("@planning_enabled")).must_equal false
  end

  it "defines a getter on team" do
    TimePilot.redis.sadd "timepilot:planning:team_ids", @healthcare.id
    _(@healthcare.planning_enabled?).must_equal true
  end

  it "defines an enabler on team" do
    @retail.enable_planning
    _(TimePilot.redis.sismember("timepilot:planning:team_ids", @retail.id)).must_equal true
  end

  it "defines a disabler on team" do
    @retail.enable_planning
    _(@retail.planning_enabled?).must_equal true
    _(@retail.instance_variable_get("@planning_enabled")).must_equal true
    @retail.disable_planning
    _(@retail.planning_enabled?).must_equal false
    _(@retail.instance_variable_get("@planning_enabled")).must_equal false
  end

  it "defines a getter on employee" do
    TimePilot.redis.sadd "timepilot:planning:employee_ids", @john.id
    _(@john.planning_enabled?).must_equal true
    _(@john.instance_variable_get("@planning_enabled")).must_equal true
  end

  it "defines an enabler on employee" do
    @jane.enable_planning
    _(TimePilot.redis.sismember("timepilot:planning:employee_ids", @jane.id)).must_equal true
  end

  it "defines a disabler on employee" do
    @jane.enable_planning
    _(@jane.planning_enabled?).must_equal true
    _(@jane.instance_variable_get("@planning_enabled")).must_equal true
    @jane.disable_planning
    _(@jane.planning_enabled?).must_equal false
    _(@jane.instance_variable_get("@planning_enabled")).must_equal false
  end

  it "defines a cardinality count on the classes" do
    @nedap.enable_planning
    @john.enable_planning
    @jane.enable_planning
    _(Company.pilot_feature_cardinality(:planning)).must_equal 1
    _(Team.pilot_feature_cardinality(:planning)).must_equal 0
    _(Employee.pilot_feature_cardinality(:planning)).must_equal 2
  end

  it "registers classes that include TimePilot::Features" do
    _(TimePilot.group_classes).must_include Company
    _(TimePilot.group_classes).must_include Team
    _(TimePilot.group_classes).must_include Employee
  end

  specify "company overrides team" do
    @nedap.enable_planning
    _(@retail.planning_enabled?).must_equal true
    _(@retail.instance_variable_get("@planning_enabled")).must_equal true
  end

  specify "team overrides employee" do
    @healthcare.enable_planning
    _(@john.planning_enabled?).must_equal true
    _(@john.instance_variable_get("@planning_enabled")).must_equal true
  end

  specify "company overrides employee" do
    @nedap.enable_planning
    _(@jane.planning_enabled?).must_equal true
    _(@jane.instance_variable_get("@planning_enabled")).must_equal true
  end
end

class CamelCasedModel
  include TimePilot::Features
  is_pilot_group
end

describe TimePilot, "converting CamelCase to camel_case" do
  it do
    _(CamelCasedModel.time_pilot_groups).must_equal ["camel_cased_model"]
  end
end

describe TimePilot do
  before do
    @acme = Company.new(1)

    @mock = MiniTest::Mock.new
    TimePilot.configure do |config|
      config.redis(@mock)
    end
  end

  after do
    TimePilot.configure do |config|
      config.redis(Redis.new)
    end
  end

  specify "calls redis only once" do
    @mock.expect(:pipelined, [true])

    _(@acme.planning_enabled?).must_equal true
    # Call the feature a second time
    # If it calls redis you will get
    # MockExpectationError: No more expects available for :pipelined: []
    _(@acme.planning_enabled?).must_equal true
  end

  specify "does not call redis to get status after disabling" do
    @mock.expect(:srem, true, ["timepilot:planning:company_ids", @acme.id])

    @acme.disable_planning
    # Call the feature again it should hit the instance variable
    # If it calls redis you will get
    # MockExpectationError: No more expects available for :pipelined: []
    _(@acme.planning_enabled?).must_equal false
  end

  specify "does not call redis to get status after enabling" do
    @mock.expect(:sadd, true, ["timepilot:planning:company_ids", @acme.id])

    @acme.enable_planning
    # Call the feature again it should hit the instance variable
    # If it calls redis you will get
    # MockExpectationError: No more expects available for :pipelined: []
    _(@acme.planning_enabled?).must_equal true
  end
end
