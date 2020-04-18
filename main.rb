require 'sinatra'
require 'dry-validation'
require './poros/task'
require './utils/loops'
require './utils/task_stats'
require './services/scheduling_service'

set :port, 3000
INPUT_FILENAME = 'tasks.json'.freeze
DEFAULT_HYPER_PERIOD_COUNT = 4


class MethodContract < Dry::Validation::Contract
  schema do
    required(:method).filled(:string)
  end

  rule(:method) do
    if value != 'rm' && value != 'edf'
      key.failure('Must be any of: "rm", "edf"')
    end
  end
end

get '/:method/?:num?' do
  hyper_period_count = params[:hyper_period_count] || DEFAULT_HYPER_PERIOD_COUNT
  res = MethodContract.new.call method: params['method']
  return { error: res.errors.to_h }.to_json if res.failure?

  method = res[:method]
  service = SchedulingService.new task_from_file
  title = "Алгоритм #{method.upcase}. Суммарная загруженность: #{service.summary_load.round(3)}"

  last_result = Loops.times(hyper_period_count) do
    result = service.run! method
    save_trace_to_file method, result, params[:num]
    result
  end
  TaskStats.count method
  erb :index, locals: {title: title, trace_data: last_result.to_json}
end

# @return [Array<Task>]
def task_from_file
  data = JSON.parse File.read(INPUT_FILENAME)
  periodic_tasks = data['periodic'].map { |h| PeriodicTask.from_json! h }
  hyper_period = SchedulingService.hyper_period periodic_tasks
  aperiodic_tasks = data['aperiodic'].map do |h|
    AperiodicTask.from_json! h, hyper_period
  end
  periodic_tasks + aperiodic_tasks
end

def save_trace_to_file(method, data, num)
  max_file_name_num = Dir["logs/#{method}#{num || '*'}.json"]
                          &.map { |name| name[-6].to_i }
                          &.max || 0
  File.open("logs/#{method}#{max_file_name_num + 1}.json", 'w') do |f|
    f.write data.to_json
  end
end
