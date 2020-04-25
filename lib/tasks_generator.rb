require 'json'

N = 38 # Число период. задач
M = 22 # Число апериод. задач

MIN_U = 0.94
MAX_U = 0.96
PACKS = [[12, 7], [13, 7], [13, 8]] # Число задач период. и апериод., распределенных по процессорам
MAX_EXEC_TIMES = [1000.0, 1000.0, 1000.0] # Макс. время выполнения задачи на каждом из процессоров
HYPERPERIOD = 300_000.0
CPU_COUNT = PACKS.length

def u!(task)
  throw "Execution time must not be greater than period #{task[:exec_time].to_f}, #{task[:period]}" if
      task[:exec_time].to_f > task[:period]
  task[:exec_time].to_f / task[:period]
end

periods = [HYPERPERIOD]
(N - 1).times do
  p = HYPERPERIOD
  loop do
    throw 'P < 1' if p < 1
    break periods << p if HYPERPERIOD % p == 0 && !periods.include?(p)
    p = (p - 0.1).round(1)
  end
end
p periods
periods.shuffle!

success_info = []
PACKS.each_with_index do |(n, m), cpu|
  loop do
    periodic_tasks = periods.first(n).each_with_index.map do |p, i|
      exec_time = rand(50...[MAX_EXEC_TIMES[cpu], p].min)
      {id: i + 1, period: p, exec_time: exec_time.round, periodic?: true }
    end
    aperiodic_tasks = (0...m).map do |i|
      p = rand(HYPERPERIOD * 0.5...HYPERPERIOD)
      exec_time = rand(50...[MAX_EXEC_TIMES[cpu], p].min)
      {id: N + i + 1, period: p, exec_time: exec_time.round, periodic?: false }
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
end
puts success_info
