Code.compile_file("#{__DIR__}/../ch04/simple_todo.ex")

defmodule TodoList.GenServerInterface do
  use GenServer

  # server functions
  @impl GenServer
  def init(_init_arg) do
    {:ok, TodoList.new()}
  end

  @impl GenServer
  def handle_call({:entries, date}, _from, list) do
    {:reply, TodoList.entries(list, date), list}
  end

  @impl GenServer
  def handle_cast({:add_entry, entry}, list) do
    {:noreply, TodoList.add_entry(list, entry)}
  end

  # interface functions
  def start() do
    GenServer.start(__MODULE__, nil, name: __MODULE__)
  end

  def add_entry(entry) do
    GenServer.cast(__MODULE__, {:add_entry, entry})
  end

  def entries(date) do
    GenServer.call(__MODULE__, {:entries, date})
  end
end
