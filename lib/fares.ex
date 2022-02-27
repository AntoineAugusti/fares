defmodule FareRule do
  defguard positive_int(x) when is_integer(x) and x > 0
  @callback can_apply?(any(), DateTime.t()) :: boolean
  @callback run(any(), [DateTime.t()], integer) :: {integer, [DateTime.t()]}
end

defmodule SingleTrip do
  @enforce_keys [:trip_duration_minutes, :cost]
  defstruct [:trip_duration_minutes, :cost]
  import FareRule, only: [positive_int: 1]
  @behaviour FareRule

  def new(trip_duration_minutes, cost)
      when positive_int(trip_duration_minutes) and positive_int(cost) do
    %__MODULE__{trip_duration_minutes: trip_duration_minutes, cost: cost}
  end

  def can_apply?(%__MODULE__{}, _), do: true
  def run(%__MODULE__{}, [], cost), do: {cost, []}

  def run(
        %__MODULE__{trip_duration_minutes: trip_duration_minutes, cost: rule_cost},
        [head | tail],
        cost
      ) do
    datetime_after = DateTime.add(head, trip_duration_minutes * 60, :second)
    {cost + rule_cost, tail |> Enum.filter(&(DateTime.compare(&1, datetime_after) == :gt))}
  end
end

defmodule ConsecutiveDays do
  @enforce_keys [:nb_days, :cost]
  defstruct [:nb_days, :cost]
  import FareRule, only: [positive_int: 1]
  @behaviour FareRule

  def new(nb_days, cost) when positive_int(nb_days) and positive_int(cost) do
    %__MODULE__{nb_days: nb_days, cost: cost}
  end

  def can_apply?(%__MODULE__{}, _), do: true
  def run(%__MODULE__{}, [], cost), do: {cost, []}

  def run(%__MODULE__{nb_days: nb_days, cost: rule_cost}, [head | tail], cost) do
    datetime_after = DateTime.add(head, nb_days * 60 * 60 * 24, :second)
    {cost + rule_cost, tail |> Enum.filter(&(DateTime.compare(&1, datetime_after) == :gt))}
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
