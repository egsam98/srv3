require "json"
# Считаем гиперпериоды, фрейм и сум. загруженность #

TASKS_FILENAME = "tasks1.json"

def sum_u(tasks)
  sum_periodic = tasks['periodic'].sum{ |t| t['exec_time'].to_f / t['period']}
  sum_aperiodic = tasks['aperiodic'].sum{ |t| t['exec_time'].to_f / t['period']}
  [sum_periodic, sum_aperiodic, sum_periodic+sum_aperiodic]
end

def nok_arr(tasks)
  periods = tasks['periodic'].map { |t| t['period'] }
  n = nok(*periods[0..1])
  periods[2..].each { |elem| n = nok(n, elem) }
  n
end

# Наим. общее кратное
def nok(a, b)
  mult = a * b
  until (a - b).zero?
    a > b ? a -= b : b -= a
  end
  mult.to_f / a
end

def frame(tasks)
  exec_times = []
  periods = []
  tasks["periodic"].each do |t|
    exec_times << t["exec_time"]
    periods << t["period"]
  end
  f = 1
  loop do
    break f if f >= exec_times.max && periods.any? { |p| p % f == 0 } &&
        periods.all? { |p| 2*f - nok(p, f) <= p }
    f += 1
  end
end

tasks = JSON.parse File.read(TASKS_FILENAME)
puts "Frame = #{frame(tasks).to_f / 1000}"
puts "Hyperperiod = НОК(#{tasks.values.flatten.map { |t| (t['period'] / 1000).round(3) }.join(', ')}) = #{nok_arr(tasks).to_f / 1000}"
sum_p, sum_ap, sum = sum_u tasks
puts "Сумма U_period: #{sum_p}", "Сумма U_aperiod: #{sum_ap}", "Сумма U: #{sum}"