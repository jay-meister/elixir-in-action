defmodule Todo.Cache do
  use GenServer

  @impl true
  def init(_arg) do
    {:ok, _pid} = DataStore.Server.start()
    {:ok, %{}}
  end

  @impl true
  def handle_call({:get_pid, name}, _from, state) do
    pid =
      case Map.fetch(state, name) do
        :error ->
          log("Todo.List instance not currently stored in cache")
          {:ok, pid} = Todo.Server.start(name)
          pid

        {:ok, pid} ->
          pid
      end

    {:reply, pid, Map.put(state, name, pid)}
  end

  # api
  def start do
    {:ok, _pid} = GenServer.start_link(__MODULE__, nil, name: __MODULE__)

    :ok
  end

  def server_process(name) do
    GenServer.call(__MODULE__, {:get_pid, name})
  end

  defp log(msg) do
    "[cache] #{msg}"
    |> IO.puts()
  end
end
