defmodule FireAlarm.Room do
  alias FireAlarm.Sources.{Smoke, Humidity, Temperature}
  alias FireAlarm.Composites.{Average, ChangeTrigger, Maintenance}
  alias Strom.{Composite, Transformer, Mixer}

  @interval 1000 * Application.compile_env!(:fire_alarm, :time_scale)
  @maintenance_interval 10000 * Application.compile_env!(:fire_alarm, :time_scale)
  @max_temperature 50
  @max_humidity 90

  def build({temp_mod, hum_mod, smoke_mod}, output_stream, maintenance_stream \\ false) do
    Composite.new([
      build_sources({temp_mod, hum_mod, smoke_mod}),
      maintenance(maintenance_stream),
      Mixer.new([:temperature, :humidity], :th_mixed),
      Transformer.new(:th_mixed, &check_warning/2, {0, 0}),
      Mixer.new([:th_mixed, :smoke], output_stream),
      Transformer.new(output_stream, &check_alarm/2, {:ok, false}),
      ChangeTrigger.build(output_stream, @interval)
    ])
  end

  defp build_sources({temp_mod, hum_mod, smoke_mod}) do
    temperature_source = Temperature.build(temp_mod.events())
    temp_avg = Average.build(:temperature, @interval, :temperature)

    humidity_source = Humidity.build(hum_mod.events())
    humidity_avg = Average.build(:humidity, @interval, :humidity)

    smoke_source = Smoke.build(smoke_mod.events())

    [temperature_source, temp_avg, humidity_source, humidity_avg, smoke_source]
  end

  def check_warning(event, acc) do
    case {event, acc} do
      {{:temperature, temperature}, {_temp, hum}}
      when temperature >= @max_temperature and hum >= @max_humidity ->
        {[:warning], {temperature, hum}}

      {{:humidity, humidity}, {temp, _hum}}
      when temp >= @max_temperature and humidity >= @max_humidity ->
        {[:warning], {temp, humidity}}

      {{:temperature, temperature}, {_temp, hum}} ->
        {[:ok], {temperature, hum}}

      {{:humidity, humidity}, {temp, _hum}} ->
        {[:ok], {temp, humidity}}
    end
  end

  def check_alarm(event, acc) do
    case {event, acc} do
      {{:smoke, true}, {temp_hum, _smoke}} ->
        {[:alarm], {temp_hum, true}}

      {{:smoke, false}, {:warning, _smoke}} ->
        {[:warning], {:warning, false}}

      {{:smoke, false}, {:ok, _smoke}} ->
        {[:ok], {:ok, false}}

      {:warning, {_, false}} ->
        {[:warning], {:warning, false}}

      {:warning, {_, true}} ->
        {[:alarm], {:warning, true}}

      {:ok, {_, true}} ->
        {[:alarm], {:ok, true}}

      {:ok, {_, false}} ->
        {[:ok], {:ok, false}}
    end
  end

  defp maintenance(false), do: []

  defp maintenance(stream) do
    Maintenance.build({:temperature, :humidity, :smoke}, @maintenance_interval, stream)
  end
end
