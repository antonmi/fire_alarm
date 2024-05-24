defmodule FireAlarm.Storage do
  alias FireAlarm.Composites.ChangeTrigger
  alias FireAlarm.Room
  alias Strom.{Composite, Transformer, Mixer}

  @interval 1000
  @maintenance_interval 10000

  def build(rooms_with_configs, output_stream, maintenance_stream \\ false) do
    rooms = build_rooms(rooms_with_configs, maintenance_stream)

    mixer = Mixer.new(Map.keys(rooms_with_configs), output_stream)

    status = Transformer.new(:status, &status_transformer/2, {MapSet.new(), MapSet.new()})

    change_trigger = ChangeTrigger.build(output_stream, @interval)

    Composite.new([
      rooms,
      mixer,
      status,
      change_trigger,
      maintenance(Map.keys(rooms_with_configs), maintenance_stream)
    ])
  end

  defp build_rooms(rooms_with_configs, maintenance_stream) do
    Enum.reduce(rooms_with_configs, [], fn {room_name, configs}, acc ->
      room =
        if maintenance_stream do
          Room.build(configs, room_name, {maintenance_stream, room_name})
        else
          Room.build(configs, room_name)
        end

      add_room_number = Transformer.new(room_name, &{room_name, &1})

      acc ++ [room, add_room_number]
    end)
  end

  defp status_transformer({room, status}, {warnings, alarms}) do
    case {room, status} do
      {room, :alarm} ->
        alarms = MapSet.put(alarms, room)
        warnings = MapSet.delete(warnings, room)
        {[define_status({warnings, alarms})], {warnings, alarms}}

      {room, :warning} ->
        alarms = MapSet.delete(alarms, room)
        warnings = MapSet.put(warnings, room)
        {[define_status({warnings, alarms})], {warnings, alarms}}

      {room, :ok} ->
        alarms = MapSet.delete(alarms, room)
        warnings = MapSet.delete(warnings, room)
        {[define_status({warnings, alarms})], {warnings, alarms}}
    end
  end

  defp define_status({warnings, alarms}) do
    cond do
      MapSet.size(alarms) >= 3 ->
        {:siren, Enum.to_list(alarms)}

      MapSet.size(alarms) > 0 ->
        {:alarm, Enum.to_list(alarms)}

      MapSet.size(warnings) > 0 ->
        {:warning, Enum.to_list(warnings)}

      true ->
        {:ok, []}
    end
  end

  defp maintenance(_rooms, false), do: []

  defp maintenance(rooms, stream) do
    maintenance_keys = Enum.map(rooms, &{stream, &1})
    maintenance_mixer = Mixer.new(maintenance_keys, stream)
    maintenance_trigger = ChangeTrigger.build(stream, @maintenance_interval)
    [maintenance_mixer, maintenance_trigger]
  end
end
