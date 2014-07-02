module TimePilot
  NAMESPACE = 'timepilot'

  def self.configure
    @config = Configuration.new
    yield @config
    @config.features.each do |feature_name|
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

  module Features
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      attr_reader :time_pilot_groups
      def is_pilot_group options={}
        @time_pilot_groups = Array(options[:overridden_by]).map { |e| e.to_s } + [self.to_s.underscore]
      end
    end

    def pilot_enable_feature(feature_name)
      TimePilot.redis.sadd TimePilot.key("#{feature_name}:#{self.class.to_s.underscore}_ids"), id
    end

    def pilot_disable_feature(feature_name)
      TimePilot.redis.srem TimePilot.key("#{feature_name}:#{self.class.to_s.underscore}_ids"), id
    end

    def pilot_feature_enabled?(feature_name)
      TimePilot.redis.pipelined {
        self.class.time_pilot_groups.each do |group|
          method = group.to_s == self.class.to_s.underscore ? 'id' : group + '_id'
          TimePilot.redis.sismember TimePilot.key("#{feature_name}:#{group}_ids"), send(method)
        end
      }.include? true
    end

  end

end
