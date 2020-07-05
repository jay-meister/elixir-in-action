defmodule Todo.Metrics do
  use Task

  def start_link(_arg) do
    IO.puts("[#{__MODULE__}] starting . . .")

    Task.start_link(&loop/0)
  end

  defp loop() do
    Process.sleep(:timer.seconds(10))
    IO.inspect(collect_metrics())
    loop()
  end

  defp collect_metrics() do
    memory = (:erlang.memory(:total) / 100_000) |> round

    [
      memory_usage: "#{memory}MB",
      process_count: :erlang.system_info(:process_count)
    ]
  end
end
