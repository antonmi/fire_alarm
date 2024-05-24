defmodule FireAlarm.Composites.MaintenanceTest do
  use ExUnit.Case
  alias FireAlarm.Composites.{Average, Maintenance}
  alias FireAlarm.Sources.{Temperature, Humidity, Smoke}

  alias Strom.{Composite, Mixer}

  def build({temps, hums, smokes}) do
    temp_source = Temperature.build(temps, test: true, timeout: 10)
    temp_avg = Average.build(:temperature, 50, :temperature)

    hum_source = Humidity.build(hums, test: true, timeout: 10)
    hum_avg = Average.build(:humidity, 50, :humidity)

    smoke_source = Smoke.build(smokes, test: true, timeout: 10)

    maintenance = Maintenance.build({:temperature, :humidity, :smoke}, 100, :problems)

    Composite.new([
      temp_source,
      temp_avg,
      hum_source,
      hum_avg,
      smoke_source,
      maintenance
    ])
  end

  test "when everything is fine" do
    temps = Enum.to_list(1..25)
    hums = Enum.to_list(1..25)
    smokes = List.duplicate(false, 24) ++ List.duplicate(true, 1)

    composite =
      {temps, hums, smokes}
      |> build()
      |> Composite.start()

    flow = Composite.call(%{}, composite)
    assert Enum.to_list(flow[:problems]) == [{:ok, []}, {:ok, []}]
  end

  test "when temperature and smoke fails" do
    temps = []
    hums = Enum.to_list(1..25)
    smokes = []

    composite =
      {temps, hums, smokes}
      |> build()
      |> Composite.start()

    flow = Composite.call(%{}, composite)

    assert Enum.to_list(flow[:problems]) == [
             {:maintenance, [:smoke, :temperature]},
             {:maintenance, [:smoke, :temperature]}
           ]
  end
end
