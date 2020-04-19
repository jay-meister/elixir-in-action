defmodule Todo.Server do
  use GenServer

  # server functions
  @impl GenServer
  def init(_init_arg) do
    {:ok, Todo.List.new()}
  end

  @impl GenServer
  def handle_call({:entries, date}, _from, list) do
    {:reply, Todo.List.entries(list, date), list}
  end

  @impl GenServer
  def handle_cast({:add_entry, entry}, list) do
    {:noreply, Todo.List.add_entry(list, entry)}
  end

  # interface functions
  def start() do
    {:ok, _pid} = GenServer.start(__MODULE__, nil)
  end

  def add_entry(pid, entry) do
    GenServer.cast(pid, {:add_entry, entry})
  end

  def entries(pid, date) do
    GenServer.call(pid, {:entries, date})
  end
end
