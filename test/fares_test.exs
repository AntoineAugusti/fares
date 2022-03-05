defmodule FaresTest do
  use ExUnit.Case, async: true
  doctest Fares

  test "compute" do
    assert Fares.compute([ConsecutiveDays.new(1, 5)], [~U[2018-11-01 10:05:00Z]]) == 5

    assert Fares.compute([ConsecutiveDays.new(1, 5)], [
             ~U[2018-11-01 10:05:00Z],
             ~U[2018-11-02 10:06:00Z]
           ])

    assert Fares.compute([ConsecutiveDays.new(1, 5), ConsecutiveDays.new(7, 7)], [
             ~U[2018-11-01 10:05:00Z],
             ~U[2018-11-02 10:06:00Z]
           ]) == 7

    assert Fares.compute([ConsecutiveDays.new(1, 5), ConsecutiveDays.new(31, 50)], [
             ~U[2018-11-01 10:05:00Z],
             ~U[2018-11-02 10:06:00Z]
           ]) == 10

    assert Fares.compute(
             [ConsecutiveDays.new(1, 5), ConsecutiveDays.new(31, 50), SingleTrip.new(60, 1)],
             [
               ~U[2018-11-01 10:05:00Z],
               ~U[2018-11-02 10:06:00Z]
             ]
           ) == 2

    assert Fares.compute(
             [ConsecutiveDays.new(1, 5), ConsecutiveDays.new(31, 50), SingleTrip.new(60, 2)],
             [
               ~U[2018-11-01 10:05:00Z],
               ~U[2018-11-01 12:05:00Z],
               ~U[2018-11-01 16:05:00Z],
               ~U[2018-11-02 10:06:00Z]
             ]
           ) == 7

    assert Fares.compute(
             [SingleTrip.new(60, 2), NightTrip.new(19, 6, 1.5)],
             [
               ~U[2018-11-01 10:05:00Z],
               ~U[2018-11-01 12:05:00Z],
               ~U[2018-11-01 16:05:00Z],
               ~U[2018-11-02 19:06:00Z],
               ~U[2018-11-02 21:06:00Z],
               ~U[2018-11-03 02:30:00Z],
               ~U[2018-11-03 09:30:00Z]
             ]
           ) == 9.5
  end

  describe "SingleTrip" do
    test "create new struct" do
      SingleTrip.new(60, 1)
    end

    test "can_apply?" do
      assert SingleTrip.can_apply?(SingleTrip.new(60, 1), ~U[2018-11-15 10:00:00Z])
    end

    test "run" do
      assert {1, []} == SingleTrip.run(SingleTrip.new(60, 1), [~U[2018-11-15 10:00:00Z]], 0)

      assert {1, []} ==
               SingleTrip.run(
                 SingleTrip.new(60, 1),
                 [~U[2018-11-15 10:00:00Z], ~U[2018-11-15 10:59:00Z]],
                 0
               )

      assert {1, [~U[2018-11-15 11:05:00Z]]} ==
               SingleTrip.run(
                 SingleTrip.new(60, 1),
                 [~U[2018-11-15 10:00:00Z], ~U[2018-11-15 11:05:00Z]],
                 0
               )
    end
  end

  describe "ConsecutiveDays" do
    test "create new struct" do
      ConsecutiveDays.new(1, 10)
    end

    test "can_apply?" do
      assert ConsecutiveDays.can_apply?(ConsecutiveDays.new(1, 10), ~U[2018-11-15 10:00:00Z])
    end

    test "run" do
      assert {15, [~U[2018-11-16 10:05:00Z]]} ==
               ConsecutiveDays.run(
                 ConsecutiveDays.new(1, 10),
                 [~U[2018-11-15 10:00:00Z], ~U[2018-11-15 19:00:00Z], ~U[2018-11-16 10:05:00Z]],
                 5
               )

      assert {15, []} ==
               ConsecutiveDays.run(
                 ConsecutiveDays.new(1, 10),
                 [~U[2018-11-15 10:00:00Z], ~U[2018-11-15 19:00:00Z]],
                 5
               )

      assert {15, []} ==
               ConsecutiveDays.run(
                 ConsecutiveDays.new(5, 10),
                 [~U[2018-11-15 10:00:00Z], ~U[2018-11-20 10:00:00Z]],
                 5
               )

      assert {5, []} == ConsecutiveDays.run(ConsecutiveDays.new(5, 10), [], 5)
    end
  end

  describe "NightTrip" do
    test "new" do
      NightTrip.new(19, 6, 5)
    end

    test "can_apply?" do
      assert NightTrip.can_apply?(NightTrip.new(19, 6, 5), ~U[2018-11-15 19:05:00Z])
      assert NightTrip.can_apply?(NightTrip.new(19, 6, 5), ~U[2018-11-15 23:50:00Z])
      refute NightTrip.can_apply?(NightTrip.new(19, 6, 5), ~U[2018-11-15 18:55:00Z])
    end

    test "run" do
      assert {2, []} == NightTrip.run(NightTrip.new(19, 6, 2), [~U[2018-11-15 19:05:00Z], ~U[2018-11-15 21:05:00Z]], 0)

      assert {2, []} ==
               NightTrip.run(
                 NightTrip.new(19, 6, 2),
                 [~U[2018-11-15 19:05:00Z], ~U[2018-11-15 21:05:00Z], ~U[2018-11-16 05:55:00Z]],
                 0
               )

      assert {3, [~U[2018-11-16 06:30:00Z]]} ==
               NightTrip.run(
                 NightTrip.new(19, 6, 2),
                 [~U[2018-11-15 19:05:00Z], ~U[2018-11-15 21:05:00Z], ~U[2018-11-16 06:30:00Z]],
                 1
               )
    end
  end
end
