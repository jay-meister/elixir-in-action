defmodule DatabaseServer do
  def start() do
    spawn(&loop/0)
  end

  def run_async(server_pid, query) do
    IO.inspect(self(), label: :caller_pid)
    send(server_pid, {:run_query, self(), query})
  end

  def get_result() do
    receive do
      {:query_result, result} -> result
    after
      5000 -> {:error, :timeout}
    end
  end

  defp loop do
    receive do
      {:run_query, caller, query} ->
        send(caller, {:query_result, run_query(query)})
    end

    loop()
  end

  defp run_query(query) do
    Process.sleep(4000)
    "query result: #{query}"
  end
end

# server_pool = 1..50 |> Enum.map(fn _ -> DatabaseServer.start() end)

# 1..10
# |> Enum.map(fn query ->
#   pid = Enum.at(server_pool, :rand.uniform(50) - 1)
#   DatabaseServer.run_async(pid, query)
# end)
# |> Enum.map(fn _ ->
#   DatabaseServer.get_result()
#   |> IO.inspect()
# end)

defmodule StatefulDatabaseServer do
  def start() do
    connection = :rand.uniform(1000)
    spawn(fn -> loop(connection) end)
  end

  def run_async(server_pid, query) do
    send(server_pid, {:run_query, self(), query})
  end

  def get_result() do
    receive do
      {:query_result, result} -> result
    after
      5000 -> {:error, :timeout}
    end
  end

  defp loop(connection) do
    receive do
      {:run_query, caller, query} ->
        send(caller, {:query_result, run_query(connection, query)})
    end

    loop(connection)
  end

  defp run_query(connection, query) do
    Process.sleep(4000)
    "Connection #{connection}: query result: #{query}"
  end
end

# server_pool = 1..50 |> Enum.map(fn _ -> DatabaseServer.start() end)

# 1..10
# |> Enum.map(fn query ->
#   pid = Enum.at(server_pool, :rand.uniform(50) - 1)
#   DatabaseServer.run_async(pid, query)
# end)
# |> Enum.map(fn _ ->
#   DatabaseServer.get_result()
#   |> IO.inspect()
# end)
