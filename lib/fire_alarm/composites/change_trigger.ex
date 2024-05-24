defmodule FireAlarm.Composites.ChangeTrigger do
  alias FireAlarm.Composites.TickSource
  alias Strom.{Composite, Mixer, Transformer}

  def build(stream_name, interval) do
    Composite.new([
      TickSource.build(:ticks, interval),
      Mixer.new([stream_name, :ticks], stream_name, no_wait: true),
      Transformer.new(stream_name, &handle_events/2, nil)
    ])
  end

  def handle_events(event, last_event) do
    case {event, last_event} do
      {:tick, nil} ->
        {[], nil}

      {:tick, last_event} ->
        {[last_event], last_event}

      {event, event} ->
        {[], event}

      {event, _last_event} ->
        {[event], event}
    end
  end
end
