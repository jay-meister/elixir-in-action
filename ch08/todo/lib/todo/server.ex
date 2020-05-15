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

  def start_link(name) do
    IO.puts("[#{__MODULE__}] starting . . .")
    GenServer.start_link(__MODULE__, name)
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
  def init(name) do
    {:ok, {name, Database.Server.get(name) || Todo.List.new()}}
  end

  @impl true
  def handle_cast({:add_entry, entry}, {name, list}) do
    list = Todo.List.add_entry(list, entry)
    Database.Server.store(name, list)

    {:noreply, {name, list}}
  end

  @impl true
  def handle_call({:entries, date}, _from, {name, list}) do
    {:reply, Todo.List.entries(list, date), {name, list}}
  end
end
