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

  defp time_now, do: Time.truncate(Time.utc_now(), :millisecond)

  @tag timeout: :infinity
  test "storage" do
    :observer.start()

    composite =
      @rooms
      |> Storage.build(:status)
      |> Composite.start()

    IO.inspect(length(composite.components), label: :storage_components)

    %{}
    |> Composite.call(composite)
    |> Map.get(:status)
    |> Stream.each(&IO.inspect(&1, label: inspect({time_now(), :status})))
    |> Stream.run()
  end

  @tag timeout: :infinity
  test "storage with maintenance" do
    :observer.start()

    composite =
      @rooms
      |> Storage.build(:status, :maintenance)
      |> Composite.start()

    IO.inspect(length(composite.components), label: :storage_components)

    flow = Composite.call(%{}, composite)

    task1 =
      Task.async(fn ->
        flow[:status]
        |> Stream.each(&IO.inspect(&1, label: inspect({time_now(), :status})))
        |> Stream.run()
      end)

    task2 =
      Task.async(fn ->
        flow[:maintenance]
        |> Stream.each(&IO.inspect(&1, label: inspect({time_now(), :maintenance})))
        |> Stream.run()
      end)

    Task.await(task1, :infinity)
    Task.await(task2, :infinity)
  end
end
