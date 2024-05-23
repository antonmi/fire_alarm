# FireAlarm

**An example problem solved with Strom**

## The problem

We are implementing a fire-alarm logic for a storage of goods.

The storage has many rooms. Each room has 3 sensors:

- Temperature sensor
- Humidity sensor
- Smoke detector

Each sensor produces event every 100ms (it may vary).

The program reports the status of the storage every second.

On the room level the logic is following:
1. If the temperature exceeds 50C and the same time the humidity exceeds 90% the program produces the `:warning` event for the room.
2. If smoke is detected the program produces the `:alarm` event for the room.
3. If everything is ok the program reports the `:ok` event.

On the storage level the logic is:
1. If everything ok, the `{:ok, []}` event is generated.
2. If there are warnings in rooms, the `{:warning, [:room_x, :room_y]}` is produced
3. If there are alarms in rooms, the `{:alarm, [:room_x, :room_y]}` is produced.
4. If there are more than 3 rooms with the `:alarm` event, then the `{:siren, [:room_x, :room_y]}` event is produced.

And there is a priority in events, the `:siren` has the highest priority, `:ok` - the lowest.
It means, if there is any event with the high priority, then only this event is generated.

In terms of streams and flow one can formulate the problem in the following way:

Input: The flow of `3 * room_number` streams:
```elixir
%{
  room_1_temperature: Stream.t([{:temperature, integer()}]),
  room_1_humidity: Stream.t([{:humidity, integer()}),
  room_1_smoke: Stream.t([{:smoke, boolean()}),
  ...
}
```

Output:
```elixir
%{
  status: [{:ok, []} | {:warning, [room()]} | {:alarm, [room()]} | {:siren, [room()]} 
}
```






