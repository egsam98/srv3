require 'sinatra'
require "sinatra/reloader"
require 'dry-validation'
require './poros/task'
require './utils/loops'
require './utils/task_stats'
require './utils/task_files'
require './services/scheduling_service'
require './services/tasks_tracer_service'
require './contracts/scheduling_method_contract'

set :port, 3000
register Sinatra::Reloader

DEFAULT_HYPER_PERIOD_COUNT = 4


def input_filename(cpu)
  "tasks#{cpu}.json"
end

get "/count/:method/?" do
  res = SchedulingMethodContract.new.call method: params['method']
  return { error: res.errors.to_h }.to_json if res.failure?
  @data = TasksTracerService.new(res[:method]).count
  erb :count
end

get '/:method/:cpu/?' do
  hyper_period_count = params[:hyper_period_count] || DEFAULT_HYPER_PERIOD_COUNT
  res = SchedulingMethodContract.new.call(method: params[:method], cpu: params[:cpu])
  return { error: res.errors.to_h }.to_json if res.failure?

  method = res[:method]
  file_name = input_filename(res[:cpu])
  TaskFiles.empty_result method

  last_result, title = Loops.times(hyper_period_count) do
    service = SchedulingService.new TaskFiles.from_file(file_name)
    title = "Алгоритм #{method.upcase}. Суммарная загруженность: #{service.summary_load.round(3)}"
    result = service.run! method
    TaskFiles.save_trace method, result
    [result, title]
  end

  erb :index, locals: {title: title, tasks: last_result, stats: TaskStats.count(method, true?(params[:naebka]))}
end

post "/naebka-starika/:method" do
  status 200
end

def true?(obj)
  obj.to_s.downcase == "true"
end
