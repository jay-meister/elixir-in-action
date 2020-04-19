defmodule DataStore do
  @db "db"

  def path(id) do
    "#{__DIR__}/#{@db}/#{id}"
  end

  def write!(id, data) do
    path(id)
    |> File.write!(:erlang.term_to_binary(data))
  end

  def read!(id) do
    path(id)
    |> File.read!()
    |> :erlang.binary_to_term()
  end
end

defmodule DataStore.Server do
  use GenServer

  def start do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def write(id, data) do
    :ok = GenServer.cast(__MODULE__, {:write, id, data})
  end

  def read(id) do
    data = GenServer.call(__MODULE__, {:read, id})
    {:ok, data}
  end

  @impl true
  def init(_) do
    {:ok, nil}
  end

  @impl true
  def handle_call({:read, id}, _from, state) do
    {:reply, DataStore.read!(id), state}
  end

  @impl true
  def handle_cast({:write, id, data}, state) do
    :ok = DataStore.write!(id, data)

    {:noreply, state}
  end
end
