defmodule FireAlarm.SourcesTest do
  use ExUnit.Case
  alias FireAlarm.Sources
  alias FireAlarm.Sources.{Smoke, Temperature, Humidity}

  alias Strom.Source

  @events [1, 2, 3, 4]

  describe "generic source" do
    test "build and call" do
      source = Sources.build(:amount, 1000, @events, test: true)

      flow = Source.call(%{}, source)

      assert Enum.to_list(flow[:amount]) == [
               {:amount, 1},
               {:amount, 2},
               {:amount, 3},
               {:amount, 4}
             ]
    end
  end

  describe "sources" do
    test "smoke" do
      source = Smoke.build([false, true], test: true)

      flow = Source.call(%{}, source)
      assert Enum.to_list(flow[:smoke]) == [{:smoke, false}, {:smoke, true}]
    end

    test "temperature" do
      source = Temperature.build(@events, test: true)

      flow = Source.call(%{}, source)

      assert Enum.to_list(flow[:temperature]) == [
               {:temperature, 1},
               {:temperature, 2},
               {:temperature, 3},
               {:temperature, 4}
             ]
    end

    test "humidity" do
      source = Humidity.build(@events, test: true)

      flow = Source.call(%{}, source)

      assert Enum.to_list(flow[:humidity]) == [
               {:humidity, 1},
               {:humidity, 2},
               {:humidity, 3},
               {:humidity, 4}
             ]
    end
  end
end
