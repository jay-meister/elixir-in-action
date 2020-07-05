defmodule MyAgent do
  use GenServer

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def update(pid, fun) do
    GenServer.call(pid, {:update, fun})
  end

  def get(pid, fun) do
    GenServer.call(pid, {:get, fun})
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:update, fun}, _from, state) do
    new_state = fun.(state)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:get, fun}, _from, state) do
    reply_with = fun.(state)
    {:reply, reply_with, state}
  end
end
