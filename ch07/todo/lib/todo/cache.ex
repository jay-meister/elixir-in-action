defmodule Todo.Cache do
  use GenServer

  def purge(pid) do
    GenServer.call(pid, {:purge})
  end

  def start do
    GenServer.start(__MODULE__, nil)
  end

  def server_process(pid, name) when is_binary(name) do
    GenServer.call(pid, {:server_process, name})
  end

  # internal callback functions
  def init(_) do
    {:ok, _pid} = Database.Server.start()
    {:ok, %{}}
  end

  def handle_call({:server_process, name}, _from, state) do
    if pid = state[name] do
      {:reply, pid, state}
    else
      # attempt to fetch todo from database
      {:ok, pid} = Todo.Server.start(name)
      {:reply, pid, Map.put(state, name, pid)}
    end
  end

  def handle_call({:purge}, _from, _state) do
    {:reply, :ok, %{}}
  end
end
