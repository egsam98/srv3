require 'sinatra'
require 'dry-validation'
require './utils/task'
require './services/scheduling_service'

set :port, 3000
INPUT_FILENAME = 'periodic_tasks.json'


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

get '/:method' do
  res = MethodContract.new.call method: params['method']
  return { error: res.errors.to_h }.to_json if res.failure?

  method = res[:method]
  service = SchedulingService.new(read_input_data)
  title = "Алгоритм #{method.upcase}. Суммарная загруженность: #{service.summary_load.round(3)}"
  erb :index, locals: { title: title, trace_data: service.run!(method).to_json }
end

# @return [Array<Task>]
def read_input_data
  file = File.read(INPUT_FILENAME)
  JSON.parse(file).map { |h| Task.from_json! h }
end
