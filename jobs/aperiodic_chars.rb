require './jobs/abstract_job'


class AperiodicCharsJob < AbstractJob
  def run
    @name = 'Подсчет статистических характеристик'
    @scheduler.every '3s' do
      count
    end
  end

  private

  def count
    puts '=' * 100
    puts "Фоновая задача: #{@name}\n\n"
    %w[rm edf].each do |method|
      puts "Алгоритм #{method.upcase}:\n\n"
      tasks = load_tasks method

      stats = {}
      tasks.group_by { |t| t['id'] }.sort.each do |id, tasks|
        delays = tasks.map { |t| t['periods'][0]['start'] - t['start'] }.sort
        stats[id] = {
          average: (delays.sum.to_f / delays.count / 1000).round(3),
          max: (delays.max.to_f / 1000).round(3)
        }
        puts "Задача №#{id}"
        puts "Времена откликов: #{delays}"
        puts "Среднее время отклика: #{stats[id][:average]}"
        puts "Макс. время отлика: #{stats[id][:max]}\n\n"
      end

      File.open("logs/#{method}_stats.json", 'w') do |f|
        f.write stats.to_json
      end
    end
    puts '=' * 100
  end

  # @return [Array<Hash>]
  def load_tasks(method)
    tasks = []
    Dir["logs/#{method}*.json"].grep(/\d+\.json/).map do |file_name|
      f = File.open file_name
      tasks += JSON.parse(f.read)
      f.close
    end
    tasks
  end
end
