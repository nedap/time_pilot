module TimePilot
  class Configuration
    attr_reader :features, :redis_store

    def initialize
      @features = []
      @redis_store = Redis.new
    end

    def feature(feature_name)
      @features.push(feature_name)
    end

    def redis(redis_store)
      @redis_store = redis_store
    end
  end
end
