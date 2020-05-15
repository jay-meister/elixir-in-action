defmodule Database do
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

defmodule Database.Server do
  use GenServer

  @db_path "#{File.cwd!()}/persist/#{Mix.env()}"

  def purge_db do
    Database.purge_db(@db_path)
  end

  def stop() do
    GenServer.stop(__MODULE__, :normal, :infinity)
  end

  def start do
    GenServer.start(__MODULE__, nil, name: __MODULE__)
  end

  def get(id) do
    GenServer.call(__MODULE__, {:get, id})
  end

  def store(id, data) do
    GenServer.cast(__MODULE__, {:store, id, data})
  end

  # internal callback functions
  @impl true
  def init(_) do
    File.mkdir_p!(@db_path)
    {:ok, @db_path}
  end

  @impl true
  def handle_call({:get, id}, _from, db_path) do
    {:reply, Database.get(db_path, id), db_path}
  end

  @impl true
  def handle_cast({:store, id, data}, db_path) do
    :ok = Database.store(db_path, id, data)
    {:noreply, db_path}
  end
end
