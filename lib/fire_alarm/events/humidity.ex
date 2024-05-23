defmodule FireAlarm.Events.NormalHumidity do
  def events do
    List.duplicate(60, 100)
  end
end

defmodule FireAlarm.Events.HighHumidity do
  def events do
    List.duplicate(60, 70) ++ List.duplicate(95, 30)
  end
end
