class RunResult < LegResult
  field :mmile, as: :minute_mile, type: Float

  def calc_ave
    if event && secs
      miles = event.miles
      self.minute_mile = secs/60/miles unless miles.nil?
    end
  end
end
