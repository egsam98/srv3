class SchedulingMethodContract < Dry::Validation::Contract
  schema do
    required(:method).filled(:string)
    optional(:cpu).filled(:string)
  end

  rule(:method) do
    if value != 'rm' && value != 'edf'
      key.failure('Must be any of: "rm", "edf"')
    end
  end

  rule(:cpu) do
    unless value.nil?
      key.failure('Must be numerical') unless /\d+/.match(value)
    end
  end
end
