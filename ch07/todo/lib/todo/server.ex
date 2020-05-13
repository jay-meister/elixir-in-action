defmodule Todo.Server do
  @moduledoc """
  We create a new Todo.Server process for each Todo.List
  A Todo.Server process holds the state of its Todo.List in memory
  Clients call Todo.Server with a pid representing the List they are operating on
  Todo.Server exposes API functions for working with a clients Todo.List
  Todo.Server API functions send messages to the specified Todo.Server process which
  operates on the internal Todo.List

  state of each Todo.Server process: %Todo.List{}
  """

  use GenServer

  # client functions called in client process which
  # send messages to one of many Todo.Server processes

  def start() do
    GenServer.start_link(__MODULE__, nil)
  end

  def add_entry(pid, entry) do
    GenServer.cast(pid, {:add_entry, entry})
  end

  def entries(pid, date) do
    GenServer.call(pid, {:entries, date})
  end

  # internal callback functions are run on seperate processes
  # I find it confusing that these functions are defined in the same module as the API functions above
  # it feels like they belong closer to the Todo.List module than the Todo.Server module

  @impl true
  def init(_) do
    {:ok, Todo.List.new()}
  end

  @impl true
  def handle_cast({:add_entry, entry}, state) do
    {:noreply, Todo.List.add_entry(state, entry)}
  end

  @impl true
  def handle_call({:entries, date}, _from, state) do
    {:reply, Todo.List.entries(state, date), state}
  end
end
