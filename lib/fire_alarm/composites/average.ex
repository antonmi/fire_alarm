defmodule FireAlarm.Composites.Average do
  alias Strom.Transformer

  def build(stream, interval, prefix) do
    Transformer.new(
      stream,
      fn event, {values, started_at} ->
        {^prefix, value} = event
        values = [value | values]

        if time_now() - started_at >= interval do
          avg = Enum.sum(values) / length(values)
          {[{prefix, avg}], {[], time_now()}}
        else
          {[], {values, started_at}}
        end
      end,
      {[], time_now()}
    )
  end

  defp time_now do
    DateTime.to_unix(DateTime.utc_now(), :millisecond)
  end
end
