defmodule FireAlarm.Composites.ChangeTrigger do
  alias FireAlarm.Composites.TickSource
  alias Strom.{Composite, Mixer, Transformer}

  def build(stream_name, interval) do
    tick_source = TickSource.build(:ticks, interval)
    mixer = Mixer.new([stream_name, :ticks], stream_name, no_wait: true)
    transformer = Transformer.new(stream_name, &handle_events/2, nil)

    Composite.new([tick_source, mixer, transformer])
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
