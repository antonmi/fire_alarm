defmodule FireAlarm.Room do
  alias FireAlarm.Sources.{Smoke, Humidity, Temperature}
  alias FireAlarm.Utils.{Average, ChangeTrigger}
  alias Strom.{Composite, Transformer, Mixer}

  @interval 1000
  @max_temperature 50
  @max_humidity 90

  def build({temp_mod, hum_mod, smoke_mod}, output_stream) do
    sources = build_sources({temp_mod, hum_mod, smoke_mod})

    mix_temp_and_hum = Mixer.new([:temperature, :humidity], :th_mixed)

    warning =
      Transformer.new(
        :th_mixed,
        fn
          {:temperature, temperature}, {_temp, hum}
          when temperature >= @max_temperature and hum >= @max_humidity ->
            {[:warning], {temperature, hum}}

          {:humidity, humidity}, {temp, _hum}
          when temp >= @max_temperature and humidity >= @max_humidity ->
            {[:warning], {temp, humidity}}

          {:temperature, temperature}, {_temp, hum} ->
            {[:ok], {temperature, hum}}

          {:humidity, humidity}, {temp, _hum} ->
            {[:ok], {temp, humidity}}
        end,
        # {temperature, humidity}
        {0, 0}
      )

    mix_all = Mixer.new([:th_mixed, :smoke], output_stream)

    alarm =
      Transformer.new(
        output_stream,
        fn
          {:smoke, true}, {temp_hum, _smoke} ->
            {[:alarm], {temp_hum, true}}

          {:smoke, false}, {:warning, _smoke} ->
            {[:warning], {:warning, false}}

          {:smoke, false}, {:ok, _smoke} ->
            {[:ok], {:ok, false}}

          :warning, {_, false} ->
            {[:warning], {:warning, false}}

          :warning, {_, true} ->
            {[:alarm], {:warning, true}}

          :ok, {_, true} ->
            {[:alarm], {:ok, true}}

          :ok, {_, false} ->
            {[:ok], {:ok, false}}
        end,
        # {temp_hum, smoke}
        {:ok, false}
      )

    change_trigger = ChangeTrigger.build(output_stream, @interval)

    Composite.new([
      sources,
      mix_temp_and_hum,
      warning,
      mix_all,
      alarm,
      change_trigger
    ])
  end

  defp build_sources({temp_mod, hum_mod, smoke_mod}) do
    temperature_source = Temperature.build(temp_mod.events())
    temp_avg = Average.build(:temperature, @interval, :temperature)

    humidity_source = Humidity.build(hum_mod.events())
    humidity_avg = Average.build(:humidity, @interval, :humidity)

    smoke_source =
      smoke_mod.events()
      |> Smoke.build()

    [temperature_source, temp_avg, humidity_source, humidity_avg, smoke_source]
  end
end
