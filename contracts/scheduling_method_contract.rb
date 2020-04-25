class SchedulingMethodContract < Dry::Validation::Contract
  schema do
    required(:method).filled(:string)
  end

  rule(:method) do
    if value != 'rm' && value != 'edf'
      key.failure('Must be any of: "rm", "edf"')
    end
  end
end
