require 'sinatra'
require 'dry-validation'
require './utils/task'
require './services/scheduling_service'
require './jobs/aperiodic_chars'

set :port, 3000
INPUT_FILENAME_PERIODIC = 'periodic_tasks.json'
INPUT_FILENAME_APERIODIC = 'aperiodic_tasks.json'

AperiodicCharsJob.new.run

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
  res = MethodContract.new.call method: params['method']
  return { error: res.errors.to_h }.to_json if res.failure?

  method = res[:method]
  service = SchedulingService.new from_files
  title = "Алгоритм #{method.upcase}. Суммарная загруженность: #{service.summary_load.round(3)}"
  result = service.run! method
  save_to_file method, result, params[:num]
  erb :index, locals: { title: title, trace_data: result.to_json }
end

# @return [Array>]
def from_files
  file = File.read INPUT_FILENAME_PERIODIC
  periodic_tasks = JSON.parse(file).map { |h| PeriodicTask.from_json! h }
  file = File.read INPUT_FILENAME_APERIODIC
  service = SchedulingService.new periodic_tasks
  hyper_period = service.hyper_period
  aperiodic_tasks = JSON.parse(file).map { |h| AperiodicTask.from_json! h, hyper_period }
  periodic_tasks + aperiodic_tasks
end

def save_to_file(method, data, num)
  max_file_name_num = Dir["logs/#{method}#{num || '*'}.json"]
                          &.map { |name| name[-6].to_i }&.max || 0
  File.open("logs/#{method}#{max_file_name_num + 1}.json", 'w') do |f|
    f.write data.to_json
  end
end
