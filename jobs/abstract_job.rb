require 'rufus-scheduler'


class AbstractJob
  def initialize
    @scheduler = Rufus::Scheduler.new
  end

  def run
    raise NotImplementedError
  end
end