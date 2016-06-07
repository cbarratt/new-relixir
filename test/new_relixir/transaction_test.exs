defmodule NewRelixir.TransactionTest do
  use ExUnit.Case, async: false
  import TestHelpers.Assertions

  alias NewRelixir.Transaction

  setup do
    :ok = :statman_histogram.init
  end

  @name "Test Transaction"

  # finish

  test "finish records elapsed time with correct key" do
    transaction = Transaction.start(@name)
    Transaction.finish(transaction)

    assert_contains(:statman_histogram.keys, {@name, :total})
  end

  test "finish records accurate elapsed time" do
    {_, elapsed_time} = :timer.tc(fn() ->
      transaction = Transaction.start(@name)
      :ok = :timer.sleep(42)
      Transaction.finish(transaction)
    end)

    [{recorded_time, _}] = :statman_histogram.get_data({@name, :total})

    assert_between(recorded_time, 42000, elapsed_time)
  end
end
