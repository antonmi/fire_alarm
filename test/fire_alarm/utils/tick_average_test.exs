defmodule FireAlarm.Utils.AverageTest do
  use ExUnit.Case
  alias FireAlarm.Utils.TickAverage
  alias FireAlarm.Sources.Temperature

  alias Strom.Composite

  @events Enum.to_list(1..15)

  test "average temperature" do
    events_source = Temperature.build(@events, test: true, timeout: 10)

    avg_composite =
      events_source
      |> TickAverage.build(50)
      |> Composite.start()

    %{temperature: temperature} = Composite.call(%{}, avg_composite)

    # temperature = Stream.each(temperature, &IO.inspect(&1))
    assert Enum.to_list(temperature) == [
             {:temperature, 2.5},
             {:temperature, 7.0},
             {:temperature, 11.5}
           ]
  end
end
