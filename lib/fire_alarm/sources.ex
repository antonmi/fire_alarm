defmodule FireAlarm.Sources do
  alias Strom.Source

  def build(stream_name, timeout, init_events, opts \\ [test: false]) do
    timeout =
      if opts[:test] do
        opts[:timeout] || 1
      else
        timeout
      end

    stream =
      Stream.resource(
        fn -> init_events end,
        fn
          [] ->
            if opts[:test] do
              {:halt, []}
            else
              {[], init_events}
            end

          events ->
            Process.sleep(timeout)
            [event | rest] = events
            {[{stream_name, event}], rest}
        end,
        fn [] -> [] end
      )

    Source.new(stream_name, stream)
  end
end

defmodule FireAlarm.Sources.Smoke do
  alias FireAlarm.Sources

  @name :smoke
  @timeout 100

  def build(events, opts \\ []) do
    timeout = div(@timeout, 2) + :rand.uniform(@timeout)
    Sources.build(@name, timeout, events, opts)
  end
end

defmodule FireAlarm.Sources.Temperature do
  alias FireAlarm.Sources

  @name :temperature
  @timeout 100

  def build(events, opts \\ []) do
    timeout = div(@timeout, 2) + :rand.uniform(@timeout)
    Sources.build(@name, timeout, events, opts)
  end
end

defmodule FireAlarm.Sources.Humidity do
  alias FireAlarm.Sources

  @name :humidity
  @timeout 100

  def build(events, opts \\ []) do
    timeout = div(@timeout, 2) + :rand.uniform(@timeout)
    Sources.build(@name, timeout, events, opts)
  end
end
