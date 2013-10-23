require 'date'


class Randgen
  DATE_TIME_EPOCH = ::DateTime.new(2015, 1, 1, 0, 0, 0)

  def self.date
    return DATE_TIME_EPOCH - rand(800)
  end
end