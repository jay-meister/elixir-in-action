defmodule Todo.Database.Operations do
  def path(db_path, id) do
    "#{db_path}/#{id}"
  end

  def store(db_path, id, data) do
    path(db_path, id)
    |> File.write!(:erlang.term_to_binary(data))
  end

  def get(db_path, id) do
    case path(db_path, id) |> File.read() do
      {:ok, contents} -> :erlang.binary_to_term(contents)
      {:error, _} -> nil
    end
  end

  def purge_db(db_path) do
    File.rm_rf!(db_path)
    File.mkdir_p!(db_path)
  end
end

defmodule Todo.Database.Worker do
  use GenServer

  alias Todo.Database.Operations

  def start_link({db_path, worker_id}) do
    via_tuple = via_tuple(worker_id)
    IO.puts("[#{__MODULE__}][#{inspect(via_tuple)}] starting . . .")
    GenServer.start_link(__MODULE__, db_path, name: via_tuple)
  end

  def get(worker_id, id) do
    via_tuple(worker_id)
    |> GenServer.call({:get, id})
  end

  def store(worker_id, id, data) do
    via_tuple(worker_id)
    |> GenServer.cast({:store, id, data})
  end

  # internal callback functions
  @impl true
  def init(db_path) do
    {:ok, db_path}
  end

  @impl true
  def handle_call({:get, id}, _from, db_path) do
    {:reply, Operations.get(db_path, id), db_path}
  end

  @impl true
  def handle_cast({:store, id, data}, db_path) do
    :ok = Operations.store(db_path, id, data)
    {:noreply, db_path}
  end

  defp via_tuple(worker_id) do
    Todo.ProcessRegistry.via_tuple({__MODULE__, worker_id})
  end
end

defmodule Todo.Database do
  alias Todo.Database

  @pool_size 3
  @db_path "#{File.cwd!()}/persist/#{Mix.env()}"

  def purge_db do
    Database.Operations.purge_db(@db_path)
  end

  def start_link() do
    IO.puts("[#{__MODULE__}] starting . . .")

    :ok = File.mkdir_p!(@db_path)

    children =
      1..@pool_size
      |> Enum.map(fn n ->
        Supervisor.child_spec({Database.Worker, {@db_path, n}}, id: {Database.Worker, n})
      end)

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end

  def get(id) do
    choose_worker(id)
    |> Database.Worker.get(id)
  end

  def store(id, data) do
    choose_worker(id)
    |> Database.Worker.store(id, data)
  end

  defp choose_worker(id) do
    :erlang.phash2(id, @pool_size) + 1
  end
end
