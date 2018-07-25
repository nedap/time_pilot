module TimePilot
  NAMESPACE = 'timepilot'
  @group_classes = []
  @mutex = Mutex.new

  def self.register_class(klass)
    @mutex.synchronize do
      @group_classes << klass
    end
  end

  class << self
    attr_reader :group_classes
  end

  def self.configure
    @config ||= Configuration.new
    yield @config
    @config.features.each { |f| define_feature_method(f) }
  end

  def self.define_feature_method(feature_name)
    Features.module_eval do
      define_method "enable_#{feature_name}" do
        pilot_enable_feature(feature_name)
      end

      define_method "disable_#{feature_name}" do
        pilot_disable_feature(feature_name)
      end

      define_method "#{feature_name}_enabled?" do
        pilot_feature_enabled?(feature_name)
      end
    end
  end

  def self.features
    @config.features
  end

  def self.redis
    @config.redis_store
  end

  def self.key(name)
    "#{NAMESPACE}:#{name}"
  end

  # Including this module makes a class a TimePilot class
  module Features
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      attr_reader :time_pilot_groups
      def is_pilot_group(options = {})
        TimePilot.register_class(self)
        @time_pilot_groups = Array(options[:overridden_by]).map(&:to_s) +
                             [to_s.underscore]
      end

      def pilot_feature_cardinality(feature_name)
        key_name = "#{feature_name}:#{to_s.underscore}_ids"
        TimePilot.redis.scard TimePilot.key(key_name)
      end
    end

    def pilot_enable_feature(feature_name)
      instance_variable_set("@#{feature_name}_enabled", true)
      key_name = "#{feature_name}:#{self.class.to_s.underscore}_ids"
      TimePilot.redis.sadd TimePilot.key(key_name), id
    end

    def pilot_disable_feature(feature_name)
      instance_variable_set("@#{feature_name}_enabled", false)
      key_name = "#{feature_name}:#{self.class.to_s.underscore}_ids"
      TimePilot.redis.srem TimePilot.key(key_name), id
    end

    def pilot_feature_enabled?(feature_name)
      unless instance_variable_defined?("@#{feature_name}_enabled")
        enabled = TimePilot.redis.pipelined do
          self.class.time_pilot_groups.each do |group|
            method = group.to_s == self.class.to_s.underscore ? 'id' : group + '_id'
            TimePilot.redis.sismember TimePilot.key("#{feature_name}:#{group}_ids"), send(method)
          end
        end.include? true

        instance_variable_set("@#{feature_name}_enabled", enabled)
      end
      instance_variable_get("@#{feature_name}_enabled")
    end

  end

end
