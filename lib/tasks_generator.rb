require 'json'

N = 39 # Число период. задач
M = 21 # Число апериод. задач

MIN_U = 0.94
MAX_U = 0.96
PACKS = [[13, 7], [13, 7], [13, 7]] # Число задач период. и апериод., распределенных по процессорам
MAX_EXEC_TIMES = [1000.0, 1000.0, 1000.0] # Макс. время выполнения задачи на каждом из процессоров
HYPERPERIOD = 243_000.0
CPU_COUNT = PACKS.length

def u!(task)
  throw "Execution time must not be greater than period #{task[:exec_time].to_f}, #{task[:period]}" if
      task[:exec_time].to_f > task[:period]
  task[:exec_time].to_f / task[:period]
end

hyper_periods_history = HYPER_PERIODS.clone
HYPER_PERIODS.each_with_index do |hyper_period, cpu|

  n, m = PACKS[cpu]
  periods = [hyper_period]
  (n - 1).times do
    p = hyper_period
    loop do
      throw 'P < 1' if p < 1
      if (hyper_period % p).zero? && !hyper_periods_history.include?(p)
        break periods << p, hyper_periods_history << p
      end

      p = (p - 0.1).round(1)
    end
  end
  p periods
  periods.shuffle!

  success_info = []
  loop do
    periodic_tasks = periods.first(n).each_with_index.map do |p, i|
      exec_time = rand(50...[MAX_EXEC_TIMES[cpu], p].min)
      {id: i + 1 + cpu * (n + m), period: p, exec_time: exec_time.round, periodic?: true}
    end

    aperiodic_tasks = (0...m).map do |i|
      p = rand(hyper_period * 0.5...hyper_period)
      exec_time = rand(50...[MAX_EXEC_TIMES[cpu], p].min)
      {id: n + i + 1 + cpu * (n + m), period: p, exec_time: exec_time.round, periodic?: false}
    end

    tasks = periodic_tasks + aperiodic_tasks
    u_sum = tasks.sum { |t| u!(t)}
    puts "U_SUM (CPU: #{cpu + 1}) = #{u_sum}"
    next puts 'ERROR: U_SUM > MAX_U' unless u_sum.between?(MIN_U, MAX_U)

    p_tasks = []
    ap_tasks = []
    tasks.each do |t|
      periodic = t.delete(:periodic?)
      periodic ? p_tasks << t : ap_tasks << t
    end
    dump = JSON.dump(periodic: p_tasks, aperiodic: ap_tasks)
    success_info << "На ЦП #{cpu + 1} #{p_tasks.length} период., #{ap_tasks.length} апериод. задач. Суммарная загруженность: #{u_sum}"
    File.write("tasks#{cpu + 1}.json", dump)

    periods.shift(n)
    break
  end

  puts success_info

end