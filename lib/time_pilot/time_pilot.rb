module TimePilot

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

  module Features
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      attr_reader :time_pilot_groups
      def is_pilot_group options={}
        @time_pilot_groups = Array(options[:overridden_by]).map { |e| e.to_s } + [self.name.downcase.to_s]
      end
    end

    def pilot_enable_feature(feature_name)
      TimePilot.redis.sadd "timepilot:#{feature_name}:#{self.class.to_s.downcase}_ids", id
    end

    def pilot_disable_feature(feature_name)
      TimePilot.redis.srem "timepilot:#{feature_name}:#{self.class.to_s.downcase}_ids", id
    end

    def pilot_feature_enabled?(feature_name)
      self.class.time_pilot_groups.each do |group|
        method = group.to_s == self.class.to_s.downcase ? 'id' : group + '_id'
        return true if TimePilot.redis.sismember "timepilot:#{feature_name}:#{group}_ids", send(method)
      end
      false
    end
  end

end
