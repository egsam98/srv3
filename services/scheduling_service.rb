require 'pqueue'


class SchedulingService
  RM_COMPARATOR = lambda { |t1, t2|
    raise 'Params must be instance of Task' unless t1.is_a?(Task) && t2.is_a?(Task)

    t1.exec_time_remaining < t2.exec_time_remaining if t1.id == t2.id
    t1.period < t2.period
  }

  EDF_COMPARATOR = lambda { |t1, t2|
    raise 'Params must be instance of Task' unless t1.is_a?(Task) && t2.is_a?(Task)

    t1.count * t1.period < t2.count * t2.period
  }

  def initialize(periodic_tasks)
    # @type [Array<Task>]
    @periodic_tasks = periodic_tasks
  end

  # @param [String]method
  # @return [Array]
  def run!(method)
    pq = case method
         when 'rm' then PQueue.new([], &RM_COMPARATOR)
         when 'edf' then PQueue.new([], &EDF_COMPARATOR)
         else raise 'Must be \"rm\" or \"edf\" as path param' end
    tasks_out = []
    (0..hyper_period).each do |moment|
      @periodic_tasks.each { |t| t.spawn moment, pq }
      pq.peek&.execute(moment, pq) { |t| tasks_out << t }
    end
    @periodic_tasks.each { |t| t.count = 0 }
    form_trace tasks_out
  end

  # @return [Float]
  def summary_load
    @periodic_tasks.sum { |t| t.exec_time.to_f / t.period }
  end

  private

  # @return [Integer]
  def hyper_period
    @periodic_tasks.map(&:period).max
  end

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
      markers = task.markers.map do |marker|
        {
          type: 'diamond',
          value: marker.time,
          fill: marker.start? ? '' : '#FF0000'
        }
      end
      {
        id: task.id,
        name: task.name,
        p: task.period / 1000,
        e: task.exec_time / 1000,
        markers: markers,
        periods: periods
      }
    end
  end

end