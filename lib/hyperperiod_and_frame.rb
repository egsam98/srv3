require "json"

TASKS_FILENAME = "tasks2.json"


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
puts "Frame = #{frame(tasks)} ms"
puts "Hyperperiod = #{nok_arr(tasks)} ms"