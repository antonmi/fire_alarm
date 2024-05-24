defmodule FireAlarm.Composites.TickSource do
  alias Strom.Source

  def build(stream_name, interval) do
    Source.new(
      stream_name,
      Stream.resource(
        fn -> nil end,
        fn nil ->
          Process.sleep(interval)
          {[:tick], nil}
        end,
        fn nil -> nil end
      )
    )
  end
end
