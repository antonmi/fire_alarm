defmodule FireAlarm.Utils.TickAverage do
  alias Strom.{Composite, Mixer, Transformer, Source, Renamer}

  def build(source, interval) do
    tick_source =
      Source.new(
        :ticks,
        Stream.resource(
          fn -> nil end,
          fn nil ->
            Process.sleep(interval)
            {[:tick], nil}
          end,
          fn nil -> nil end
        )
      )

    mixer = Mixer.new([source.name, :ticks], :mixed, no_wait: true)

    batch_transformer =
      Transformer.new(
        :mixed,
        fn event, acc ->
          case event do
            :tick ->
              {[Enum.reverse(acc)], []}

            {_name, number} ->
              {[], [number | acc]}
          end
        end,
        []
      )

    avg_transformer =
      Transformer.new(
        :mixed,
        fn event ->
          if length(event) > 0 do
            avg = Enum.sum(event) / length(event)
            {source.name, avg}
          else
            {source.name, nil}
          end
        end
      )

    renamer = Renamer.new(%{mixed: source.name})

    Composite.new([source, tick_source, mixer, batch_transformer, avg_transformer, renamer])
  end
end
