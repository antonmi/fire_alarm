defmodule FireAlarm.Composites.Maintenance do
  alias FireAlarm.Composites.TickSource
  alias Strom.{Composite, Mixer, Splitter, Transformer}

  def build({temp_name, hum_name, smoke_name}, interval, output) do
    Composite.new([
      Splitter.new(temp_name, %{temp_name => & &1, temp_maintenance: & &1}),
      Splitter.new(hum_name, %{hum_name => & &1, hum_maintenance: & &1}),
      Splitter.new(smoke_name, %{smoke_name => & &1, smoke_maintenance: & &1}),
      Mixer.new([:temp_maintenance, :hum_maintenance, :smoke_maintenance], :maintenance),
      TickSource.build(:ticks, interval),
      Mixer.new([:ticks, :maintenance], output, no_wait: true),
      Transformer.new(
        output,
        handle_event({temp_name, hum_name, smoke_name}),
        # {temp, hum, smoke}
        {false, false, false}
      )
    ])
  end

  def handle_event({temp_name, hum_name, smoke_name}) do
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
    end
  end
end
