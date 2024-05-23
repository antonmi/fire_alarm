defmodule FireAlarm.RoomTest do
  use ExUnit.Case
  alias FireAlarm.Room

  alias Strom.Composite
#  alias FireAlarm.Events.{NormalTemperature, NormalHumidity, NoSmoke}
  alias FireAlarm.Events.{HighTemperature, HighHumidity, WithSmoke}

  @tag timeout: :infinity
  test "build" do
    #    :observer.start
    composite =
      {HighTemperature, HighHumidity, WithSmoke}
      |> Room.build(:room1)
      |> Composite.start()

    IO.inspect(length(composite.components), label: :room_components)

    flow = Composite.call(%{}, composite)

    flow[:room1]
    |> Stream.each(&IO.inspect(&1, label: :room1))
    |> Stream.run()
  end
end
