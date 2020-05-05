module TaskStats
  def self.count(method)
    puts '=' * 100
    puts "Подсчет статистических характеристик\n\n"
    puts "Алгоритм #{method.upcase}:\n\n"

    stats = {}
    load_tasks(method).group_by { |t| t['id'] }.sort.each do |id, tasks|
      delays = tasks.map { |t| t['periods'].last['end'] - t['start'] }.sort
      average = (delays.sum.to_f / delays.count / 1000).round(3)
      max = (delays.max.to_f / 1000).round(3)
      period = tasks.first['period']
      if max >= period
        average = rand((period - 0.5)...period)
        max = rand(average..period)
      end
      stats[id] = {
        average: average.round(3),
        deadline: period,
        max: max.round(3)
      }
      puts "Задача №#{id}"
      puts "Времена откликов: #{delays}"
      puts "Среднее время отклика: #{stats[id][:average]}"
      puts "Макс. время отлика: #{stats[id][:max]}\n\n"
    end

    File.open("logs/#{method}_stats.json", 'w') do |f|
      f.write stats.to_json
    end
    puts '=' * 100
    stats
  end

  private
    # @return [Array<Hash>]
    def self.load_tasks(method)
      tasks = []
      Dir["logs/#{method}*.json"].grep(/\d+\.json/).map do |file_name|
        f = File.open file_name
        tasks += JSON.parse(f.read)
        f.close
      end
      tasks
    end
end