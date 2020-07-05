defmodule Todo.ProcessRegistry do
  def start_link() do
    IO.puts("[#{__MODULE__}] starting . . .")
    Registry.start_link(name: __MODULE__, keys: :unique)
  end

  def via_tuple(id) do
    {:via, Registry, {__MODULE__, id}}
  end

  def child_spec(_) do
    Supervisor.child_spec(
      Registry,
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    )
  end
end
