require './utils/exponential_time_generator'


class AbstractTask
  attr_reader :id, :period, :exec_time, :exec_time_remaining, :exec_moments,
              :name, :markers, :start
  attr_accessor :count

  Marker = Struct.new(:time, :start?)

  def initialize(id, period, exec_time, start)
    @id = id
    @start = start
    @exec_time = exec_time
    @exec_time_remaining = exec_time
    @exec_moments = []
    @markers = []
    @period = period
    @count = 0
  end

  # @param [Integer]moment
  # @param [PriorityQueue<Task>]pq
  # @param [Proc<Task>]on_pop
  def execute(moment, pq, &on_pop)
    @markers << Marker.new(moment, true) if @exec_time == @exec_time_remaining
    @exec_time_remaining -= 1
    @exec_moments << moment
    return unless @exec_time_remaining.zero?

    pq.pop
    @markers << Marker.new(moment, false)
    on_pop.call self
  end

  # @param [Integer]moment
  # @param [PQueue]pq
  # @abstract
  def spawn(moment, pq)
    raise NotImplementedError
  end
end


class PeriodicTask < AbstractTask
  # @overload
  def self.from_json!(json)
    raise JSON::ParserError('JSON must have id, period, exec_time keys') if
        %w[id period exec_time].any? { |k| !json.key? k }

    new json['id'], json['period'], json['exec_time']
  end

  # @param [Integer]id
  # @param [Integer]period
  # @param [Integer]exec_time
  def initialize(id, period, exec_time, start = nil)
    super id, period, exec_time, start
    @name = "Задача №#{id} (p: #{period.to_f / 1000}s, e: #{exec_time.to_f / 1000}s"
  end

  # @overload
  def spawn(moment, pq)
    return unless (moment % @period).zero?

    @count += 1
    copy = self.class.new(@id, @period, @exec_time, moment)
    copy.count = @count
    pq << copy
  end
end


class AperiodicTask < AbstractTask
  attr_reader :lambda

  # @param [Integer]id
  # @param [Integer]period
  # @param [Integer]exec_time
  # @param [Integer]hyper_period
  def initialize(id, period, exec_time, hyper_period, start = nil)
    @lambda = 1.0 / period
    start ||= ExponentialTimeGenerator.gen(@lambda, hyper_period)
    super id, period, exec_time, start
    @name = "Задача №#{id} (lambda: #{(@lambda*1000).round(3)}, start: #{@start} e: #{exec_time.to_f / 1000}s"
  end

  # @overload
  def self.from_json!(json, hyper_period)
    raise JSON::ParserError('JSON must have id, period, exec_time keys') if
        %w[id period exec_time].any? { |k| !json.key? k }

    new json['id'], json['period'], json['exec_time'],  hyper_period
  end

  # @overload
  def spawn(moment, pq)
    return unless moment == @start

    pq << self.class.new(@id, @period, @exec_time, @start)
    # @start += KnuthPoissonRandom.gen(@lambda) // task must be called once
  end
end