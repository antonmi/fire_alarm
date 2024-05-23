defmodule FireAlarm.Composites.AverageTest do
  use ExUnit.Case
  alias FireAlarm.Composites.Average
  alias FireAlarm.Sources.Temperature

  alias Strom.Composite

  @events Enum.to_list(1..15)

  test "average temperature" do
    events_source = Temperature.build(@events, test: true, timeout: 10)

    avg_transformer = Average.build(:temperature, 50, :temperature)

    composite =
      [events_source, avg_transformer]
      |> Composite.new()
      |> Composite.start()

    %{temperature: temperature} = Composite.call(%{}, composite)

    # temperature = Stream.each(temperature, &IO.inspect(&1))
    assert Enum.to_list(temperature) == [
             {:temperature, 2.5},
             {:temperature, 7.0},
             {:temperature, 12.0}
           ]
  end
end
