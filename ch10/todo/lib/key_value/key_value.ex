defmodule KeyValue do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def put(key, value) do
    GenServer.cast(__MODULE__, {:put, key, value})
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def init(_) do
    {:ok, %{}}
  end

  def handle_cast({:put, key, value}, store) do
    {:noreply, Map.put(store, key, value)}
  end

  def handle_call({:get, key}, _, store) do
    {:reply, Map.get(store, key), store}
  end
end
