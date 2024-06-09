defmodule FireAlarm.ClusterTest do
  use ExUnit.Case
  alias FireAlarm.Room

  alias Strom.{Composite, Transformer, Mixer}
  alias FireAlarm.Events.{NormalTemperature, NormalHumidity, NoSmoke}
  alias FireAlarm.Events.{HighTemperature, HighHumidity, WithSmoke}

  @tag timeout: :infinity
  test "room" do
    :observer.start()
    [node1, node2, node3] = LocalCluster.start_nodes("fire_alarm", 3, applications: [:fire_alarm])

    room1 = Room.build({HighTemperature, HighHumidity, WithSmoke}, :room1)
    room2 = Room.build({HighTemperature, HighHumidity, WithSmoke}, :room2)
    room3 = Room.build({NormalTemperature, NormalHumidity, NoSmoke}, :room3)

    # remote composites
    room1 = :rpc.call(node1, Composite, :start, [room1])
    room2 = :rpc.call(node2, Composite, :start, [room2])
    room3 = :rpc.call(node3, Composite, :start, [room3])

    add_names =
      Enum.map([:room1, :room2, :room3], fn room -> Transformer.new(room, &{room, &1}) end)

    mixer = Mixer.new([:room1, :room2, :room3], :rooms)
    # local composite
    output =
      [add_names, mixer]
      |> Composite.new()
      |> Composite.start()

    Process.sleep(100)

    flow =
      %{}
      # remote
      |> Composite.call(room1)
      # remote
      |> Composite.call(room2)
      # remote
      |> Composite.call(room3)
      # local
      |> Composite.call(output)

    flow[:rooms]
    |> Stream.each(&IO.inspect(&1))
    |> Stream.run()
  end
end
