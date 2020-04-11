class Task
  include Comparable
  attr_reader :id, :exec_time, :exec_time_remaining, :period, :exec_moments,
              :name, :markers
  attr_accessor :count

  Marker = Struct.new(:time, :start?)

  # @param [Hash]json
  # @return [Task]
  def self.from_json!(json)
    raise JSON::ParserError('JSON must have id, period, exec_time keys') if
        %w[id period exec_time].any? { |k| !json.key? k }

    Task.new json['id'], json['period'], json['exec_time']
  end

  def initialize(id, period, exec_time)
    @id = id
    @name = "Задача №#{id} (p: #{period.to_f / 1000}s, e: #{exec_time.to_f / 1000}s"
    @period = period
    @exec_time = exec_time
    @exec_time_remaining = exec_time
    @exec_moments = []
    @markers = []
    @count = 0
  end

  # @param [Integer]moment
  # @param [PriorityQueue<Task>]pq
  # @param [Proc<Task>]on_pop
  def execute(moment, pq, &on_pop)
    @markers << Marker.new(moment, true) if @exec_time == @exec_time_remaining
    @exec_time_remaining -= 1
    @exec_moments.push moment
    return unless @exec_time_remaining.zero?

    pq.pop
    @markers << Marker.new(moment, false)
    on_pop.call self
  end

  # @param [Integer]moment
  # @param [PQueue]pq
  def spawn(moment, pq)
    return unless (moment % @period).zero?

    @count += 1
    copy = Task.new(@id, @period, @exec_time)
    copy.count = @count
    pq << copy
  end
end