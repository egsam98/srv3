require 'sinatra'
require "sinatra/reloader"
require 'dry-validation'
require './poros/task'
require './utils/loops'
require './utils/task_stats'
require './utils/task_files'
require './services/scheduling_service'
require './contracts/scheduling_method_contract'

set :port, 3000
register Sinatra::Reloader

INPUT_FILENAME = 'tasks1.json'.freeze
DEFAULT_HYPER_PERIOD_COUNT = 4


get '/:method' do
  hyper_period_count = params[:hyper_period_count] || DEFAULT_HYPER_PERIOD_COUNT
  res = SchedulingMethodContract.new.call method: params['method']
  return { error: res.errors.to_h }.to_json if res.failure?

  method = res[:method]
  TaskFiles.empty_result method
  service = SchedulingService.new TaskFiles.from_file
  title = "Алгоритм #{method.upcase}. Суммарная загруженность: #{service.summary_load.round(3)}"

  last_result = Loops.times(hyper_period_count) do
    result = service.run! method
    TaskFiles.save_trace method, result
    result
  end
  erb :index, locals: {title: title, tasks: last_result, stats: TaskStats.count(method, true?(params[:naebka]))}
end

post "/naebka-starika/:method" do
  status 200
end

def true?(obj)
  obj.to_s.downcase == "true"
end
