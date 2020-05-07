defmodule Todo.Server do
  use GenServer

  # server functions
  @impl GenServer
  def init(name) do
    case DataStore.Server.get(name) do
      nil -> {:ok, {name, Todo.List.new()}}
      list = %Todo.List{} -> {:ok, {name, list}}
    end
  end

  @impl GenServer
  def handle_call({:entries, date}, _from, {name, list}) do
    {:reply, Todo.List.entries(list, date), {name, list}}
  end

  @impl GenServer
  def handle_cast({:add_entry, entry}, {name, list}) do
    list = Todo.List.add_entry(list, entry)
    DataStore.Server.store(name, list)
    {:noreply, {name, list}}
  end

  # interface functions
  def start(todo_list_name) do
    {:ok, _pid} = GenServer.start(__MODULE__, todo_list_name)
  end

  def add_entry(pid, entry) do
    GenServer.cast(pid, {:add_entry, entry})
  end

  def entries(pid, date) do
    GenServer.call(pid, {:entries, date})
  end
end
