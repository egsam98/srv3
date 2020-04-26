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
        puts h['periods'], id
        {
          length: h['periods'].last['end'] - h['periods'].first['start'],
          call_time: h['start'],
          start_time: h['periods'].first['start']
        }
      end

      { id: id, counts: counts }
    end
  end

end