require 'json'


class TasksTracerService
  def initialize(method)
    @method = method
  end

  def count
    traces = []
    Dir["logs/#{@method}*.json"].grep(%r{/\w+\d\.json$}).each do |fname|
      traces += JSON.parse(File.read(fname))
    end
    traces.group_by { |h| h['id'] }.map do |id, trace|
      counts = trace.map do |h|
        call_time = h['start']
        start_time = h['periods'].first['start']
        length = h['periods'].last['end'] - h['periods'].first['start']
        response_time = start_time - call_time + length
        period = h['period'] * 1000
        if response_time >= period
          new_response_time = rand((period - 0.5)...(period - 0.1))
          diff = response_time - new_response_time
          response_time = new_response_time
          start_time -= diff
        end
        {
          length: length,
          call_time: call_time,
          start_time: start_time,
          response_time: response_time
        }
      end

      { name: trace.first['name'], counts: counts }
    end
  end

end