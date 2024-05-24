defmodule FireAlarm.RoomTest do
  use ExUnit.Case
  alias FireAlarm.Room

  alias Strom.Composite
  #  alias FireAlarm.Events.{NormalTemperature, NormalHumidity, NoSmoke}
  alias FireAlarm.Events.{HighTemperature, HighHumidity, WithSmoke}

  @tag timeout: :infinity
  test "room" do
    composite =
      {HighTemperature, HighHumidity, WithSmoke}
      |> Room.build(:room1)
      |> Composite.start()

    IO.inspect(length(composite.components), label: :room_components)

    %{}
    |> Composite.call(composite)
    |> Map.get(:room1)
    |> Stream.each(&IO.inspect(&1, label: :room1))
    |> Stream.run()
  end

  @tag timeout: :infinity
  test "room with maintenance" do
    composite =
      {HighTemperature, HighHumidity, WithSmoke}
      |> Room.build(:room1, {:maintenance, :room_1})
      |> Composite.start()

    IO.inspect(length(composite.components), label: :room_components)

    flow = Composite.call(%{}, composite)

    task1 =
      Task.async(fn ->
        flow[:room1]
        |> Stream.each(&IO.inspect(&1, label: :room1))
        |> Stream.run()
      end)

    task2 =
      Task.async(fn ->
        flow[{:maintenance, :room_1}]
        |> Stream.each(&IO.inspect(&1, label: :maintenance))
        |> Stream.run()
      end)

    Task.await(task1, :infinity)
    Task.await(task2, :infinity)
  end
end
