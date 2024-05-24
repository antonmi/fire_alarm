defmodule FireAlarm.Composites.Maintenance do
  alias Strom.{Composite, Mixer, Source, Splitter, Transformer}

  def build({temp_name, hum_name, smoke_name}, interval, output) do
    temp_splitter = Splitter.new(temp_name, %{temp_name => & &1, temp_maintenance: & &1})
    hum_splitter = Splitter.new(hum_name, %{hum_name => & &1, hum_maintenance: & &1})
    smoke_splitter = Splitter.new(smoke_name, %{smoke_name => & &1, smoke_maintenance: & &1})

    mix_sensors =
      Mixer.new([:temp_maintenance, :hum_maintenance, :smoke_maintenance], :maintenance)

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

    mix_ticks = Mixer.new([:ticks, :maintenance], output, no_wait: true)

    transformer =
      Transformer.new(
        output,
        fn
          {^temp_name, _value}, {_temp, hum, smoke} ->
            {[], {true, hum, smoke}}

          {^hum_name, _value}, {temp, _hum, smoke} ->
            {[], {temp, true, smoke}}

          {^smoke_name, _value}, {temp, hum, _smoke} ->
            {[], {temp, hum, true}}

          :tick, {true, true, true} ->
            {[{:ok, []}], {false, false, false}}

          :tick, {temp, hum, smoke} ->
            problems =
              {temp, hum, smoke}
              |> Tuple.to_list()
              |> Enum.zip([temp_name, hum_name, smoke_name])
              |> Enum.reduce([], fn {true_false, name}, acc ->
                if true_false do
                  acc
                else
                  [name | acc]
                end
              end)

            {[{:maintenance, problems}], {false, false, false}}
        end,
        # {temp, hum, smoke}
        {false, false, false}
      )

    Composite.new([
      temp_splitter,
      hum_splitter,
      smoke_splitter,
      mix_sensors,
      tick_source,
      mix_ticks,
      transformer
    ])
  end
end
