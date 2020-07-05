defmodule Todo.Cache do
  def child_spec(_opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :worker
    }
  end

  def start_link() do
    IO.puts("[#{__MODULE__}] starting . . .")

    DynamicSupervisor.start_link(
      name: __MODULE__,
      strategy: :one_for_one
    )
  end

  def start_child(name) do
    DynamicSupervisor.start_child(__MODULE__, {Todo.Server, name})
  end

  def server_process(name) when is_binary(name) do
    case start_child(name) do
      {:ok, pid} ->
        IO.puts("[Todo.Server] starting . . .")
        pid

      {:error, {:already_started, pid}} ->
        pid
    end
  end
end
