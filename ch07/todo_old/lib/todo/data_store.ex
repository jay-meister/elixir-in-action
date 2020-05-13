defmodule DataStore do
  def write!(path, data) do
    File.write!(path, :erlang.term_to_binary(data))
  end

  def read(path) do
    case File.read(path) do
      # TODO: Remove
      {:ok, ""} -> nil
      {:ok, contents} -> :erlang.binary_to_term(contents)
      _ -> nil
    end
  end
end

defmodule DataStore.Worker do
  use GenServer

  def start(db_dir, server_pid) do
    GenServer.start_link(__MODULE__, {db_dir, server_pid})
  end

  def store(pid, id, data) do
    :ok = GenServer.cast(pid, {:write, id, data})
  end

  def get(pid, id) do
    _data = GenServer.call(pid, {:read, id})
  end

  @impl true
  def init({db_dir, server_pid}) do
    {:ok, {db_dir, server_pid}}
  end

  @impl true
  def handle_call({:read, id}, _from, {db_dir, server_pid}) do
    data =
      path(db_dir, id)
      |> DataStore.read()

    {:reply, data, {db_dir, server_pid}}
  end

  @impl true
  def handle_cast({:write, id, data}, {db_dir, server_pid}) do
    :ok =
      path(db_dir, id)
      |> DataStore.write!(data)

    # I can't guarantee that the state will be updated before the
    # DataStore Worker is registered as finished
    DataStore.Server.worker_finished(self(), id)

    {:noreply, {db_dir, server_pid}}
  end

  defp path(db_dir, id) do
    "#{db_dir}/#{id}"
  end
end

defmodule DataStore.Server do
  use GenServer

  @db_dir "./persist"

  def db_dir do
    case Mix.env() do
      :dev -> "#{@db_dir}/dev"
      :test -> "#{@db_dir}/test"
    end
  end

  # interface
  def start do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def store(id, data) do
    :ok =
      get_worker_pid(id)
      |> DataStore.Worker.store(id, data)
  end

  def get(id) do
    get_worker_pid(id)
    |> DataStore.Worker.get(id)
  end

  # private
  defp get_worker_pid(name) do
    GenServer.call(__MODULE__, {:get_worker_pid, name})
  end

  def worker_finished(worker_pid, name) do
    GenServer.cast(__MODULE__, {:worker_finished, worker_pid, name})
  end

  # callback
  @impl true
  def init(_) do
    File.mkdir_p!(db_dir())

    {:ok, pid_1} = DataStore.Worker.start(db_dir(), self())
    {:ok, pid_2} = DataStore.Worker.start(db_dir(), self())
    {:ok, pid_3} = DataStore.Worker.start(db_dir(), self())

    {:ok,
     %{
       pid_1 => [],
       pid_2 => [],
       pid_3 => []
     }}
  end

  @impl true
  def handle_call({:get_worker_pid, name}, _from, state) do
    case Enum.find(state, fn {_worker_pid, queue} -> name in queue end) do
      nil ->
        # todo is not currently being worked on by any worker, so pick worker with shortest queue
        [{worker_pid, queue} | _] =
          Enum.sort(state, fn {_pid_1, queue_1}, {_pid_2, queue_2} ->
            length(queue_1) <= length(queue_2)
          end)

        {:reply, worker_pid, Map.put(state, worker_pid, [name | queue])}

      {worker_pid, queue} ->
        {:reply, worker_pid, Map.put(state, worker_pid, [name | queue])}
    end
    |> IO.inspect()
  end

  @impl true
  def handle_cast({:worker_finished, worker_pid, name}, state) do
    log("worker #{inspect(worker_pid)} finished working with #{inspect(name)}")

    {:noreply, Map.put(state, worker_pid, List.delete(state[worker_pid], name))}
  end

  defp log(msg) do
    IO.inspect("[#{__MODULE__}] #{msg}")
  end
end

# Todo.Cache.start()
# Enum.each(1..30, fn n ->
#   name = if rem(n, 5) == 0, do: "hanna", else: "jack"
#   spawn(fn ->
#     pid = Todo.Cache.server_process(name)
#     Todo.Server.add_entry(pid, %{date: Date.utc_today(), title: "Task: #{n}"})
#   end)
# end)

# in doing this, we seem to get a build up of "jack" tasks
# {:reply, #PID<0.245.0>,
#  %{
#    #PID<0.244.0> => ["jack", "jack", "jack", "jack"],
#    #PID<0.245.0> => ["hanna", "hanna"],
#    #PID<0.246.0> => []
#  }}

# iex(6)> Todo.Cache.server_process("jack") |> Todo.Server.entries(Date.utc_today())  |> Enum.sort_by(& &1.id)
# [
#   %{date: ~D[2020-05-12], id: 1, title: "Task: 1"},
#   %{date: ~D[2020-05-12], id: 2, title: "Task: 2"},
#   %{date: ~D[2020-05-12], id: 3, title: "Task: 3"},
#   %{date: ~D[2020-05-12], id: 4, title: "Task: 4"},
#   %{date: ~D[2020-05-12], id: 5, title: "Task: 6"},
#   %{date: ~D[2020-05-12], id: 6, title: "Task: 7"},
#   %{date: ~D[2020-05-12], id: 7, title: "Task: 8"},
#   %{date: ~D[2020-05-12], id: 8, title: "Task: 9"},
#   %{date: ~D[2020-05-12], id: 9, title: "Task: 11"},
#   %{date: ~D[2020-05-12], id: 10, title: "Task: 12"},
#   %{date: ~D[2020-05-12], id: 11, title: "Task: 13"},
#   %{date: ~D[2020-05-12], id: 12, title: "Task: 14"},
#   %{date: ~D[2020-05-12], id: 13, title: "Task: 16"},
#   %{date: ~D[2020-05-12], id: 14, title: "Task: 17"},
#   %{date: ~D[2020-05-12], id: 15, title: "Task: 18"},
#   %{date: ~D[2020-05-12], id: 16, title: "Task: 19"},
#   %{date: ~D[2020-05-12], id: 17, title: "Task: 21"},
#   %{date: ~D[2020-05-12], id: 18, title: "Task: 22"},
#   %{date: ~D[2020-05-12], id: 19, title: "Task: 23"},
#   %{date: ~D[2020-05-12], id: 20, title: "Task: 24"},
#   %{date: ~D[2020-05-12], id: 21, title: "Task: 26"},
#   %{date: ~D[2020-05-12], id: 22, title: "Task: 27"},
#   %{date: ~D[2020-05-12], id: 23, title: "Task: 28"},
#   %{date: ~D[2020-05-12], id: 24, title: "Task: 29"}
# ]
# iex(7)> Todo.Cache.server_process("hanna") |> Todo.Server.entries(Date.utc_today())  |> Enum.sort_by(& &1.id)
# [
#   %{date: ~D[2020-05-12], id: 1, title: "Task: 5"},
#   %{date: ~D[2020-05-12], id: 2, title: "Task: 10"},
#   %{date: ~D[2020-05-12], id: 3, title: "Task: 15"},
#   %{date: ~D[2020-05-12], id: 4, title: "Task: 20"},
#   %{date: ~D[2020-05-12], id: 5, title: "Task: 25"},
#   %{date: ~D[2020-05-12], id: 6, title: "Task: 30"}
# ]
