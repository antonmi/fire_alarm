defmodule FireAlarm.Composites.ChangeTrigger do
  alias Strom.{Composite, Mixer, Transformer, Source}

  def build(stream_name, interval) do
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

    mixer = Mixer.new([stream_name, :ticks], stream_name, no_wait: true)

    transformer =
      Transformer.new(
        stream_name,
        fn event, last_event ->
          case {event, last_event} do
            {:tick, nil} ->
              {[], nil}

            {:tick, last_event} ->
              {[last_event], last_event}

            {event, event} ->
              {[], event}

            {event, _last_event} ->
              {[event], event}
          end
        end,
        nil
      )

    Composite.new([tick_source, mixer, transformer])
  end
end
