module Loops

  # @param [Integer]count
  # @return last result in iteration
  def self.times(count, &block)
    count.times do |i|
      result = block.call
      break result if i == count - 1
    end
  end
end