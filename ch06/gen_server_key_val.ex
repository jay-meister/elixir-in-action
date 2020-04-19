defmodule KeyVal do
  use GenServer

  # interface functions
  def start() do
    GenServer.start(__MODULE__, nil)
  end

  def get(pid, key) do
    GenServer.call(pid, {:get, key})
  end

  def put(pid, key, val) do
    GenServer.cast(pid, {:put, key, val})
  end

  # server callback functions

  @impl true
  def init(_arg) do
    :timer.send_interval(5000, self(), :cleanup)
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:put, key, value}, state) do
    new_state = Map.put(state, key, value)
    {:noreply, new_state}
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    {:reply, state[key], state}
  end

  @impl true
  def handle_info(:cleanup, state) do
    IO.puts("[cleanup] starting")
    IO.puts("[cleanup] ...")
    IO.puts("[cleanup] done")

    {:noreply, state}
  end
end
