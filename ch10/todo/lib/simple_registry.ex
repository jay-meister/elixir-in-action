defmodule SimpleReg do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def register(name) do
    GenServer.call(__MODULE__, {:register, self(), name})
  end

  def whereis(name) do
    GenServer.call(__MODULE__, {:whereis, name})
  end

  @impl true
  def init(state) do
    Process.flag(:trap_exit, true)
    {:ok, state}
  end

  @impl true
  def handle_call({:register, pid, pname}, _, state) do
    case Map.fetch(state, pname) do
      :error ->
        Process.link(pid)
        {:reply, :ok, Map.put(state, pname, pid)}

      {:ok, _pid} ->
        {:reply, :error, state}
    end
  end

  @impl true
  def handle_call({:whereis, pname}, _, state) do
    case Map.fetch(state, pname) do
      :error ->
        {:reply, nil, state}

      {:ok, pid} ->
        {:reply, pid, state}
    end
  end

  @impl true
  def handle_info({:EXIT, pid, reason}, state) do
    IO.inspect(reason, label: :exit_reason)

    state =
      state
      |> Enum.reject(fn {_k, v} -> pid == v end)
      |> Map.new()

    {:noreply, state}
  end
end

defmodule T do
  def t do
    IO.inspect(self(), label: :iex)
    SimpleReg.start_link()

    spawn(fn ->
      IO.inspect(self(), label: :spawned)
      SimpleReg.register("jack") |> IO.inspect()
      SimpleReg.whereis("jack") |> IO.inspect()

      SimpleReg.whereis("jack")
      |> Process.exit(:kill)
    end)
  end
end
