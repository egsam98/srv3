module TaskFiles
  def self.empty_result(method)
    Dir["logs/#{method}*.json"].each do |filename|
      File.delete filename
    end
  end

  # @return [Array<Task>]
  def self.from_file
    data = JSON.parse File.read(INPUT_FILENAME)
    periodic_tasks = data['periodic'].map { |h| PeriodicTask.from_json! h }
    hyper_period = SchedulingService.hyper_period periodic_tasks
    aperiodic_tasks = data['aperiodic'].map do |h|
      AperiodicTask.from_json! h, hyper_period
    end
    periodic_tasks + aperiodic_tasks
  end

  def self.save_trace(method, data)
    max_file_name_num = Dir["logs/#{method}*.json"]
                            &.map { |name| name[-6].to_i }
                            &.max || 0
    File.open("logs/#{method}#{max_file_name_num + 1}.json", 'w') do |f|
      f.write data.to_json
    end
  end
end