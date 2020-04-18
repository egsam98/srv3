require 'pqueue'
require './poros/task'


class SchedulingService
  RM_COMPARATOR = lambda { |t1, t2|
    raise 'Params must be instance of Task' unless
        t1.is_a?(AbstractTask) && t2.is_a?(AbstractTask)
    return false if t1.is_a?(PeriodicTask) && t2.is_a?(AperiodicTask)
    return true if t2.is_a?(PeriodicTask) && t1.is_a?(AperiodicTask)
    if t1.is_a?(PeriodicTask) && t2.is_a?(AperiodicTask)
      return t1.exec_time_remaining < t2.exec_time_remaining if t1.id == t2.id
      return t1.period < t2.period
    end
    t1.start < t2.start
  }

  EDF_COMPARATOR = lambda { |t1, t2|
    raise 'Params must be instance of Task' unless
        t1.is_a?(AbstractTask) && t2.is_a?(AbstractTask)
    return true if t1.is_a?(AperiodicTask) && t2.is_a?(PeriodicTask)
    return false if t2.is_a?(AperiodicTask) && t1.is_a?(PeriodicTask)
    if t1.is_a?(PeriodicTask) && t2.is_a?(AperiodicTask)
      return t1.exec_time_remaining < t2.exec_time_remaining if t1.id == t2.id
      return t1.count * t1.period < t2.count * t2.period
    end
    t1.start < t2.start
  }

  def initialize(tasks)
    # @type [Array<Task>]
    @tasks = tasks
  end

  # @param [String]method
  # @return [Array]
  def run!(method)
    pq = case method
         when 'rm' then PQueue.new([], &RM_COMPARATOR)
         when 'edf' then PQueue.new([], &EDF_COMPARATOR)
         else raise 'Must be \"rm\" or \"edf\" as path param' end
    tasks_out = []
    (0..self.class.hyper_period(@tasks)).each do |moment|
      @tasks.each { |t| t.spawn moment, pq }
      pq.peek&.execute(moment, pq) { |t| tasks_out << t }
    end
    @tasks.each { |t| t.count = 0 }
    form_trace tasks_out
  end

  # @return [Float]
  def summary_load
    @tasks.sum do |t|
      raise 'Unknown subclass of Task' unless t.is_a? AbstractTask
      t.exec_time.to_f / t.period
    end
  end

  # @return [Integer]
  def self.hyper_period(tasks)
    tasks.map { |t| t.period if t.is_a? PeriodicTask }.compact.max
  end

  private
    # @param [Array<Task>]tasks_out
    # @return [Array]
    def form_trace(tasks_out)
      tasks_out.map do |task|
        periods = []
        task.exec_moments.each do |moment|
          if !periods.empty? && moment - periods.last[:end] == 1
            periods.last[:end] = moment
            next
          end
          periods << { start: moment, end: moment }
        end
        {
          id: task.id,
          name: task.name,
          p: task.period.to_f / 1000,
          start: task.start,
          lambda: task.is_a?(AperiodicTask) ? (task.lambda.to_f * 1000).round(3) : nil,
          e: task.exec_time.to_f / 1000,
          markers: [],
          periods: periods
        }
      end
    end

end