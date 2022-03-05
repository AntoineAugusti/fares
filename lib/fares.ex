defmodule FareRule do
  defguard positive_int(x) when is_integer(x) and x > 0
  defguard positive_number(x) when is_number(x) and x > 0
  @callback can_apply?(any(), DateTime.t()) :: boolean
  @callback run(any(), [DateTime.t()], integer) :: {integer, [DateTime.t()]}

  def run_for_minutes(_, [], cost), do: {cost, []}

  def run_for_minutes(%{minutes: minutes, cost: rule_cost}, [head | tail], cost) do
    datetime_after = DateTime.add(head, minutes * 60, :second)
    {cost + rule_cost, tail |> Enum.filter(&(DateTime.compare(&1, datetime_after) == :gt))}
  end
end

defmodule SingleTrip do
  @enforce_keys [:trip_duration_minutes, :cost]
  defstruct [:trip_duration_minutes, :cost]
  import FareRule
  @behaviour FareRule

  def new(trip_duration_minutes, cost)
      when positive_int(trip_duration_minutes) and positive_number(cost) do
    %__MODULE__{trip_duration_minutes: trip_duration_minutes, cost: cost}
  end

  def can_apply?(%__MODULE__{}, _), do: true

  def run(%__MODULE__{trip_duration_minutes: minutes, cost: rule_cost}, trips, cost) do
    run_for_minutes(%{minutes: minutes, cost: rule_cost}, trips, cost)
  end
end

defmodule NightTrip do
  @enforce_keys [:hour_start, :next_day_hour_end, :cost]
  defstruct [:hour_start, :next_day_hour_end, :cost]
  import FareRule
  @behaviour FareRule
  def new(hour_start, next_day_hour_end, cost)
      when positive_int(hour_start) and positive_int(next_day_hour_end) and positive_number(cost) and
             hour_start <= 24 and next_day_hour_end <= 24 do
    %__MODULE__{hour_start: hour_start, next_day_hour_end: next_day_hour_end, cost: cost}
  end

  def can_apply?(%__MODULE__{hour_start: hour_start}, %DateTime{hour: hour}) do
    hour >= hour_start
  end

  def run(%__MODULE__{}, [], cost), do: {cost, []}

  def run(%__MODULE__{next_day_hour_end: hour_end, cost: rule_cost}, [head | tail], cost) do
    datetime_end = %{DateTime.add(head, 60 * 60 * 24, :second) | hour: hour_end}
    {cost + rule_cost, tail |> Enum.filter(&(DateTime.compare(&1, datetime_end) == :gt))}
  end
end

defmodule ConsecutiveDays do
  @enforce_keys [:nb_days, :cost]
  defstruct [:nb_days, :cost]
  import FareRule
  @behaviour FareRule

  def new(nb_days, cost) when positive_int(nb_days) and positive_number(cost) do
    %__MODULE__{nb_days: nb_days, cost: cost}
  end

  def can_apply?(%__MODULE__{}, _), do: true

  def run(%__MODULE__{nb_days: nb_days, cost: rule_cost}, trips, cost) do
    run_for_minutes(%{minutes: nb_days * 60 * 24, cost: rule_cost}, trips, cost)
  end
end

defmodule Fares do
  def compute(rules, trips), do: compute(0, rules, trips)
  def compute(cost, _rules, []), do: cost

  def compute(cost, rules, trips) do
    rules
    |> Enum.filter(& &1.__struct__.can_apply?(&1, Enum.at(trips, 0)))
    |> Enum.map(fn rule ->
      {new_cost, remaining_trips} = rule.__struct__.run(rule, trips, cost)
      compute(new_cost, rules, remaining_trips)
    end)
    |> Enum.min()
  end
end
