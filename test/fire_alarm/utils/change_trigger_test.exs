defmodule FireAlarm.Utils.ChangeTriggerTest do
  use ExUnit.Case
  alias FireAlarm.Utils.ChangeTrigger
  alias FireAlarm.Sources.Smoke

  alias Strom.Composite

  @events List.duplicate(false, 2) ++ [true] ++ List.duplicate(false, 5)

  test "test" do
    events_source = Smoke.build(@events, test: true, timeout: 10)

    change_trigger = ChangeTrigger.build(:smoke, 50)

    composite =
      [events_source, change_trigger]
      |> Composite.new()
      |> Composite.start()

    %{smoke: smoke} = Composite.call(%{}, composite)

    #    smoke = Stream.each(smoke, &IO.inspect(&1))
    assert Enum.to_list(smoke) == [
             {:smoke, false},
             {:smoke, true},
             {:smoke, false},
             {:smoke, false}
           ]
  end
end
