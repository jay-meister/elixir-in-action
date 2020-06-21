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

  def start_link(db_path) do
    IO.puts("[#{__MODULE__}] starting . . .")
    GenServer.start_link(__MODULE__, db_path)
  end

  def get(pid, id) do
    GenServer.call(pid, {:get, id})
  end

  def store(pid, id, data) do
    GenServer.cast(pid, {:store, id, data})
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
end

defmodule Todo.Database do
  alias Todo.Database

  def db_path() do
    path =
      Application.fetch_env!(:todo, :database)
      |> Keyword.fetch!(:path)

    Path.join(File.cwd!(), path)
  end

  def purge_db do
    db_path()
    |> Database.Operations.purge_db()
  end

  def child_spec(_) do
    IO.puts("[#{__MODULE__}] starting . . .")

    :ok = db_path() |> File.mkdir_p!()

    :poolboy.child_spec(
      __MODULE__,
      [
        name: {:local, __MODULE__},
        worker_module: Todo.Database.Worker,
        size: 3
      ],
      [db_path()]
    )
  end

  def get(id) do
    choose_worker(fn pid ->
      Database.Worker.get(pid, id)
    end)
  end

  def store(id, data) do
    choose_worker(fn pid ->
      Database.Worker.store(pid, id, data)
    end)
  end

  defp choose_worker(fun) do
    :poolboy.transaction(__MODULE__, fun, 6000)
  end
end
