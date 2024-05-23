defmodule FireAlarm.Events.NormalTemperature do
  def events do
    List.duplicate(25, 100)
  end
end

defmodule FireAlarm.Events.HighTemperature do
  def events do
    List.duplicate(25, 50) ++ List.duplicate(70, 50)
  end
end

defmodule FireAlarm.Events.BrokenTemperature do
  def events do
    []
  end
end
