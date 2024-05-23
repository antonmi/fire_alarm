defmodule FireAlarm.Events.NoSmoke do
  def events do
    List.duplicate(false, 100)
  end
end

defmodule FireAlarm.Events.WithSmoke do
  def events do
    List.duplicate(false, 80) ++ List.duplicate(true, 10) ++ List.duplicate(false, 10)
  end
end
