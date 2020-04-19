defmodule Messaging do
  @moduledoc """
  Builds a parallel map function (Messaging.async_queries/1)

  Use as follows:
  $ iex ch05/prrocess_messaging.ex
  iex> Messaging.async_queries(1..10)
  """

  def slow_query(arg) do
    Process.sleep(1000)
    "query result: #{arg}"
  end

  def async_query(pid, arg) do
    spawn(fn ->
      result = slow_query(arg)
      send(pid, result)
    end)
  end

  def async_queries(args) do
    pid = self()

    Enum.map(args, fn arg ->
      async_query(pid, arg)
    end)

    Enum.map(args, fn _ ->
      receive do
        anything -> "RECEIVED: #{anything}"
      end
    end)
  end
end
