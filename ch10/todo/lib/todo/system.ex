defmodule Todo.System do
  def start_link() do
    children = [Todo.ProcessRegistry, Todo.Database, Todo.Cache, Todo.Metrics]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
