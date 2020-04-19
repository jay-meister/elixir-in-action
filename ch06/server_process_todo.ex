defmodule TodoList.ServerProcessInterface do
  # compile ServerProcess module
  Code.compile_file("#{__DIR__}/server_process.ex")

  # compile TodoList module
  Code.compile_file("#{__DIR__}/../ch04/simple_todo.ex")

  # server functions
  def init() do
    TodoList.new()
  end

  def handle_cast({:add_entry, entry}, list) do
    {:ok, TodoList.add_entry(list, entry)}
  end

  def handle_call({:entries, date}, list) do
    {:ok, TodoList.entries(list, date), list}
  end

  # interface functions
  def start() do
    ServerProcess.start(__MODULE__)
  end

  def add_entry(pid, entry) do
    ServerProcess.cast(pid, {:add_entry, entry})
  end

  def entries(pid, date) do
    ServerProcess.call(pid, {:entries, date})
  end
end
