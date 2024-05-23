defmodule FireAlarm.Storage do
  alias FireAlarm.Utils.ChangeTrigger
  alias FireAlarm.Room
  alias Strom.{Composite, Transformer, Mixer}

  @interval 1000

  def build(rooms_with_configs, output_stream) do
    rooms =
      Enum.reduce(rooms_with_configs, [], fn {room_name, configs}, acc ->
        room = Room.build(configs, room_name)
        add_room_number = Transformer.new(room_name, &{room_name, &1})

        acc ++ [room, add_room_number]
      end)

    mixer = Mixer.new(Map.keys(rooms_with_configs), output_stream)

    status =
      Transformer.new(
        :status,
        fn {room, status}, {warnings, alarms} ->
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
        end,
        # {warnings, alarms}
        {MapSet.new(), MapSet.new()}
      )

    change_trigger = ChangeTrigger.build(output_stream, @interval)

    Composite.new([
      rooms,
      mixer,
      status,
      change_trigger
    ])
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
end
