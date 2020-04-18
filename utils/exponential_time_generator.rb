module ExponentialTimeGenerator
  include Math

  # @param [Float]lambda
  # @return [Integer]
  def self.gen(lambda, max_time)
    loop do
      random = (-1.0 / lambda * Math.log(rand)).round
      return random if random < max_time
    end
  end

end