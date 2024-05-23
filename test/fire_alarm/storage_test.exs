defmodule FireAlarm.StorageTest do
  use ExUnit.Case
  alias FireAlarm.Storage

  alias Strom.Composite
  alias FireAlarm.Events.{NormalTemperature, NormalHumidity, NoSmoke}
  alias FireAlarm.Events.{HighTemperature, HighHumidity, WithSmoke}

  @count 100

  @fire_rooms Enum.reduce(1..3, %{}, fn i, acc ->
                name = String.to_atom("room#{i}")
                Map.put(acc, name, {HighTemperature, HighHumidity, WithSmoke})
              end)

  @ok_rooms Enum.reduce(4..(@count - 2), %{}, fn i, acc ->
              name = String.to_atom("room#{i}")
              Map.put(acc, name, {NormalTemperature, NormalHumidity, NoSmoke})
            end)

  @fire_rooms2 Enum.reduce((@count - 2)..@count, %{}, fn i, acc ->
                 name = String.to_atom("room#{i}")
                 Map.put(acc, name, {HighTemperature, HighHumidity, WithSmoke})
               end)

  @rooms @fire_rooms |> Map.merge(@ok_rooms) |> Map.merge(@fire_rooms2)

  @tag timeout: :infinity
  test "build" do
    :observer.start()

    composite =
      @rooms
      |> Storage.build(:status)
      |> Composite.start()

    IO.inspect(length(composite.components), label: :storage_components)

    flow = Composite.call(%{}, composite)

    flow[:status]
    |> Stream.each(&IO.inspect(&1, label: Time.truncate(Time.utc_now(), :millisecond)))
    |> Stream.run()
  end
end
