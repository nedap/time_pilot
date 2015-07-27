require 'erb'

module TimePilot
  # Rack application displaying member counts
  class Web
    def call(env)
      req = Rack::Request.new(env)
      case req.path_info
      when '/'
        dashboard
      else
        not_found
      end
    end

    # TODO: use Redis pipelining
    def dashboard
      @total_count = TimePilot.features.map do |feature_name|
        counts = TimePilot.group_classes.map do |klass|
          [klass.to_s, klass.pilot_feature_cardinality(feature_name)]
        end.to_h
        [feature_name, counts]
      end.to_h
      erb :index
    end

    def not_found
      [404, { 'Content-Type' => 'text/html' }, ['Not Found']]
    end

    def erb(view)
      [
        200,
        { 'Content-Type' => 'text/html' },
        [ERB.new(read_template(view)).result(binding)]
      ]
    end

    def read_template(view)
      File.read(File.join(__dir__, '..', '..', 'web', "#{view}.html.erb"))
    end
  end
end
